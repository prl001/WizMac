/*
 *  WizFileDownload.m
 *  WizMac
 *
 *  Created by Eric Fry on Mon May 19 2008.
 *  Copyright (c) 2008. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 */

#import "WizFile.h"
#import "WizFileDownload.h"

#define WIZ_CHUNKSIZE 33554432

@implementation WizFileDownload

+(WizFileDownload *) wizFileDownload: (WizFile *) aWizFile Delegate: (id) d
{
	return [[[self alloc] initWithWizFile: aWizFile Delegate: d] autorelease];
}

-(id)init
{
	self = [super init];
	wizFile = nil;
	dataFile = nil;
	delegate = nil;
	wizDownload = nil;
	trunc = nil;
	resumeFromPartialDownload = YES;
	makeTS = YES;

	status = WizFileDownload_New; 

	[self setDownloadPath: @""];

	[self initDLRateCalc];

	return self;
}

-(id)initWithWizFile: (WizFile *) aWizFile Delegate: (id) d
{
	self = [self init];
	
	wizFile = aWizFile;
	[wizFile retain];

	delegate = d;
	[delegate retain];

	status = WizFileDownload_Queued;

	return self;
}

-(void) initDLRateCalc
{
	short i;

	for(i=0;i<WIZ_NUM_SAMPLES;i++)
		rate.sample[i] = 0;

	rate.sampleIndex = 0;
	rate.timer = nil;
	rate.bytesDownloaded = 0;
}

-(void) resumeFromPartialDownload: (BOOL) answer
{
	resumeFromPartialDownload = answer;
}

-(void) startDLRateCalc
{
	rate.bytesDownloaded = bytesDownloaded;
	rate.timer = [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector:@selector(updateDLRateCalc:) userInfo: nil repeats: YES];
	[rate.timer retain];
}

- (void) updateDLRateCalc: (NSTimer *) aTimer
{
	rate.sample[rate.sampleIndex] = (unsigned int)(bytesDownloaded - rate.bytesDownloaded);
	if(rate.sampleIndex == WIZ_NUM_SAMPLES - 1)
		rate.sampleIndex = 0;
	else
		rate.sampleIndex++;
		
	rate.bytesDownloaded = bytesDownloaded;
}

-(unsigned int) avgDownloadRate
{
	short i;
	unsigned int avgBytesPerSecond = 0;

	for(i = 0;i < WIZ_NUM_SAMPLES; i++)
		avgBytesPerSecond += rate.sample[i];
	
	return (avgBytesPerSecond / WIZ_NUM_SAMPLES) * 2;
}

-(WizFile *) wizFile
{
	return wizFile;
}

-(WizFileDownloadStatus) status
{
	return status;
}

-(unsigned long long) filesize
{
	return [wizFile filesize];
}

-(unsigned long long) bytesDownloaded
{
	return bytesDownloaded;
}

-(NSString *)bytesDownloadedString
{
	return [NSString stringWithFormat: @"%.1LfMB", (long double)bytesDownloaded / (long double)(1024 * 1024)];
}

-(double) percentageDownloaded
{
	double percentage = (double)((double long)bytesDownloaded / (double long)[wizFile filesize]) * 100;
	return percentage;
}

-(bool) isDownloading
{
	if(status == WizFileDownload_InProgress || status == WizFileDownload_Paused || status == WizFileDownload_Retrying)
		return YES;

	return NO;
}

-(bool) checkForExistingDownload
{
	NSString *file = [NSString stringWithFormat: @"%@/%@", localPath, [wizFile localFilenameFromFormatString]];
	NSFileManager *fm = [NSFileManager defaultManager];
	
	return [fm fileExistsAtPath: file];
}

-(bool) checkForExistingPartialDownload
{
	NSFileManager *fm = [NSFileManager defaultManager];
	
	return [fm fileExistsAtPath: [self partialDownloadDir]];
}


-(bool) setDownloadPath: (NSString *) aPath
{
	if([self isDownloading] == YES)
		return NO;

	localPath = [aPath copy];
	[localPath retain];
	
	return YES;
}

//FIXME we need to move these values into instance variables. because they could change during download.
-(NSString *) partialDownloadDir
{
	return [NSString stringWithFormat: @"%@/%@.part", localPath, [wizFile localFilenameFromFormatString]];
}

-(NSString *) completeDownloadFilename
{
	return [NSString stringWithFormat: @"%@/%@", localPath, [wizFile localFilenameFromFormatString]];
}

-(NSString *) downloadPath
{
	return localPath;
}

-(bool) downloadWithDownloadPath: (NSString *) aPath 
{
	[self setDownloadPath: aPath];
	
	return [self download];
}

-(bool) download
{
	if([self isDownloading] == YES)
		return NO;

	makeTS = [[NSUserDefaults standardUserDefaults] boolForKey: @"WizPrefDownloadUseTSFormat"];
	status = WizFileDownload_InProgress;

	trunc = [NSMutableData dataWithLength: 4028];
	[trunc retain];

	[self downloadTrunc];

	return YES;
}

-(void) downloadTrunc
{
	NSString *truncPath = [NSString stringWithFormat: @"%@/trunc", [WizConnect urlEncode: [wizFile remotePath]]];

NSLog(@"truncPath = %@", truncPath);

	wizDownload = [[wizFile wizConnect] getFileAsynchronouslyWithPath: truncPath data: trunc delegate: self];

	return;
}

-(void) downloadHeader
{
	if([self setupPartialDownloadDir] == NO)
		return;
	
	NSString *headerPath = [NSString stringWithFormat: @"%@/header.%@", [WizConnect urlEncode: [wizFile remotePath]], [wizFile type]];

NSLog(@"headerPath = %@", headerPath);

	[data release];
	data = [NSMutableData dataWithLength: 4028];
	[data retain];

	[dataFilename release];
	dataFilename = [NSString stringWithString: @"header"];
	[dataFilename retain];
		
	wizDownload = [[wizFile wizConnect] getFileAsynchronouslyWithPath: headerPath data: data delegate: self];

	return;
}

-(void) downloadStat
{
	NSError *fileError = nil;

	//save header file
	NSLog([NSString stringWithFormat: @"%@/header.%@", partialDownloadDir, [wizFile type]]);
	if([data writeToFile: [NSString stringWithFormat: @"%@/header.%@", partialDownloadDir, [wizFile type]] options:  NSAtomicWrite error: &fileError]  == NO)
		return;

	NSString *statPath = [NSString stringWithFormat: @"%@/stat", [WizConnect urlEncode: [wizFile remotePath]]];

NSLog(@"statPath = %@", statPath);

	[data release];
	data = [NSMutableData dataWithLength: 96];
	[data retain];

	[dataFilename release];
	dataFilename = [NSString stringWithString: @"stat"];
	[dataFilename retain];
	
	wizDownload = [[wizFile wizConnect] getFileAsynchronouslyWithPath: statPath data: data delegate: self];

	return;
}

-(BOOL) setupPartialDownloadDir
{
	NSError *fileError = nil;
	NSFileManager *fm = [NSFileManager defaultManager];

	trunc_index = 0;

	partialDownloadDir = [NSString stringWithFormat: @"%@/%@.part", localPath, [wizFile localFilenameFromFormatString]];
	[partialDownloadDir retain];
	
	if([fm fileExistsAtPath: partialDownloadDir] == YES)
	{
		if(resumeFromPartialDownload == NO)
		{
			if([fm removeFileAtPath: partialDownloadDir handler: nil] == YES)
			{
				if([fm createDirectoryAtPath: partialDownloadDir attributes: nil] == NO) //create a new fresh dir
				{
					[self failWithErrorTitle: @"Creating partial download directory" errorDesc: partialDownloadDir errorCode: 0];
					return NO;
				}
			}
			else
			{
				[self failWithErrorTitle: @"Deleting old download" errorDesc: partialDownloadDir errorCode: 0];
				return NO;
			}
		}
	}
	else
	{
		if([fm createDirectoryAtPath: partialDownloadDir attributes: nil] == NO)
		{
			[self failWithErrorTitle: @"Creating partial download directory" errorDesc: partialDownloadDir errorCode: 0];
			return NO;
		}
	}
	
	//save trunc file
	NSLog([NSString stringWithFormat: @"%@/trunc", partialDownloadDir]);
	if([trunc writeToFile: [NSString stringWithFormat: @"%@/trunc", partialDownloadDir] options:  NSAtomicWrite error: &fileError]  == NO)
		return NO;

	return YES;
}

-(void) downloadWiz
{
	NSError *fileError = nil;
	//save stat file
	NSLog([NSString stringWithFormat: @"%@/stat", partialDownloadDir]);
	if([data writeToFile: [NSString stringWithFormat: @"%@/stat", partialDownloadDir] options:  NSAtomicWrite error: &fileError]  == NO)
		return;
		
	[dataFilename release];
	dataFilename = [NSString stringWithString: @""];
	[dataFilename retain];
	
	bytesDownloaded = 0;

	downloadStartDate = [NSDate date];

	[self downloadSelectChunk];

	[self startDLRateCalc];

}

-(void) downloadSelectChunk
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *path;
	int num_chunks = [wizFile numberOfChunks];
	int i;
	unsigned int filesize = 0;
	unsigned int chunk_size;
	unsigned int offset_in_file;
	unsigned int total_chunk_length;
	int chunk_number;

	unsigned char *bytes = (unsigned char *)[trunc bytes];

	bytesDownloaded = 0;
		
	for(i=0;i < num_chunks;i++)
	{
		chunk_number = EndianU16_LtoN(*(UInt16 *)&bytes[trunc_index * 24 + 0x8]);
		path = [NSString stringWithFormat: @"%@/%04d", partialDownloadDir, chunk_number];
		chunk_size = EndianU32_LtoN(*(UInt32 *)&bytes[i * 24 + 0x14]);
		offset_in_file = EndianU32_LtoN(*(UInt32 *)&bytes[i * 24 + 0xC]);
		
		total_chunk_length = chunk_size + offset_in_file;
NSLog(@"Checking for %@", path);
		if([fm fileExistsAtPath: path] == NO)
		{
			[self downloadNextChunk];
			return;
		}
		else
		{
			NSDictionary *attr = [fm fileAttributesAtPath: path traverseLink: NO];
			filesize = [attr fileSize];
NSLog(@"Found with filesize = %d, need size to be %d", filesize, total_chunk_length); 
			if(filesize < total_chunk_length)
			{
				bytesDownloaded += filesize;
				[self downloadPartialChunk: chunk_number startOffset: filesize length: total_chunk_length - filesize];
				return;
			}
		}

		bytesDownloaded += total_chunk_length;
		trunc_index++;
	}

	return;
}

-(void) downloadPartialChunk: (int) chunk_number startOffset: (unsigned int) offset length: (unsigned int) length
{
	NSString *path = [NSString stringWithFormat: @"%@/%04d", partialDownloadDir, chunk_number];
	
	[dataFile release];
	dataFile = [NSFileHandle fileHandleForUpdatingAtPath: path];
	[dataFile seekToEndOfFile];
	[dataFile retain];

	path = [NSString stringWithFormat: @"%@/%04d", [WizConnect urlEncode: [wizFile remotePath]], chunk_number];
	
	wizDownload = [[wizFile wizConnect] getFileAsynchronouslyWithPath: path appendToLocalFile: dataFile startOffset: offset maxLength: length delegate: self];
	trunc_index++;
}

-(void) downloadNextChunk
{
	NSString *path;

	unsigned char *bytes = (unsigned char *)[trunc bytes];
	int chunk_number = EndianU16_LtoN(*(UInt16 *)&bytes[trunc_index * 24 + 0x8]);

	path = [NSString stringWithFormat: @"%@/%04d", partialDownloadDir, chunk_number];

	FILE *f = fopen([path cString], "w");
	if(f == NULL)
	{
		[self failWithErrorTitle: @"Creating file" errorDesc: path errorCode: 0];
		return;
	}

	fclose(f);

	[dataFile release];
	dataFile = [NSFileHandle fileHandleForUpdatingAtPath: path];
	[dataFile seekToEndOfFile];
	[dataFile retain];
	
	path = [NSString stringWithFormat: @"%@/%04d", [WizConnect urlEncode: [wizFile remotePath]], chunk_number];
		
	NSLog(@"Downloading: %d %@", trunc_index, path);

	wizDownload = [[wizFile wizConnect] getFileAsynchronouslyWithPath: path appendToLocalFile: dataFile startOffset: 0 maxLength: 0 delegate: self];
	trunc_index++;
}

-(void) downloadTS
{
	NSFileManager *fm = [NSFileManager defaultManager];


	if([self setupPartialDownloadDir] == NO)
		return;

	NSString *datafile = [NSString stringWithFormat: @"%@/data.ts", partialDownloadDir];

	if([fm fileExistsAtPath: datafile] == NO)
	{
		//make sure file exists
		//FIXME find a better way to make an empty file.
		FILE *f = fopen([datafile cString], "w");
		if(f == NULL)
		{
			[self failWithErrorTitle: @"Creating file" errorDesc: datafile errorCode: 0];
			return;
		}

		fclose(f);
	}

	dataFile = [NSFileHandle fileHandleForUpdatingAtPath: datafile];
	[dataFile retain];

	//unsigned char *bytes = (unsigned char *)[trunc bytes];

	bytesDownloaded = 0;

	downloadStartDate = [NSDate date];

	[self downloadTSSelectChunk];

	[self startDLRateCalc];
		
}

-(void) downloadTSSelectChunk
{
	unsigned long long dataFileSize = [dataFile seekToEndOfFile];
	if(dataFileSize == [wizFile filesize])
	{
		return [self finishDownload];
	}
	
	if(dataFileSize > 0)
	{
		[self downloadTSPartialChunk: dataFileSize];
	}
	else
		[self downloadTSNextChunk];

	return;
}

//resume downloading a partial chunk
-(void) downloadTSPartialChunk: (unsigned long long) fsize
{
	NSString *path;
	//long double tmp_index = (long double)fsize / WIZ_CHUNKSIZE;
	//trunc_index = (int)floor((double)tmp_index);
	int num_chunks = [wizFile numberOfChunks];
	int startOffset;
	int i;
	unsigned long long trunc_size = 0;
	unsigned int chunk_size;
	unsigned int offset_in_file;
	unsigned int length;

	unsigned char *bytes = (unsigned char *)[trunc bytes];

	bytesDownloaded = fsize;
		
	for(i=0;i < num_chunks;i++)
	{
		chunk_size = EndianU32_LtoN(*(UInt32 *)&bytes[i * 24 + 0x14]);
		offset_in_file = EndianU32_LtoN(*(UInt32 *)&bytes[i * 24 + 0xC]);

		NSLog(@"trunc_size = %qu chunk_size = %d offset_in_chunk = %d", trunc_size + chunk_size, chunk_size, offset_in_file);
		if((trunc_size + chunk_size) > fsize)
		{
			trunc_index = i;
			startOffset = (int)(fsize - trunc_size); //the amount we've already downloaded in this chunk.
			length = chunk_size - startOffset;
			startOffset += offset_in_file;
			
			break;
		}
		trunc_size += chunk_size;
	}

	int chunk_number = EndianU16_LtoN(*(UInt16 *)&bytes[trunc_index * 24 + 0x8]);

	path = [NSString stringWithFormat: @"%@/%04d", [WizConnect urlEncode: [wizFile remotePath]], chunk_number];

	NSLog(@"Downloading: %@\n fsize = %qu startOffset = %d chunk_size = %d", path, fsize, startOffset, chunk_size);
	
	//data = [NSMutableData dataWithLength: 33554432];
	
	wizDownload = [[wizFile wizConnect] getFileAsynchronouslyWithPath: path appendToLocalFile: dataFile startOffset: startOffset maxLength: length delegate: self];
	trunc_index++;
}

-(void) downloadTSNextChunk
{
	NSString *path;

	unsigned char *bytes = (unsigned char *)[trunc bytes];
	int chunk_number = EndianU16_LtoN(*(UInt16 *)&bytes[trunc_index * 24 + 0x8]);
	unsigned int startOffset = EndianU32_LtoN(*(UInt32 *)&bytes[trunc_index * 24 + 0xc]);
	unsigned int length = EndianU32_LtoN(*(UInt32 *)&bytes[trunc_index * 24 + 0x14]);

	//if(trunc_index == 1)
	//	chunk_number = 17;

	path = [NSString stringWithFormat: @"%@/%04d", [WizConnect urlEncode: [wizFile remotePath]], chunk_number];

	if(startOffset == 0)
		length = 0;

		
	NSLog(@"Downloading: %d %@", trunc_index, path);
	
	//data = [NSMutableData dataWithLength: 33554432];
	
	wizDownload = [[wizFile wizConnect] getFileAsynchronouslyWithPath: path appendToLocalFile: dataFile startOffset: startOffset maxLength: length delegate: self];
	trunc_index++;
}

-(void) finishDownload
{
	NSFileManager *fm = [NSFileManager defaultManager];

	NSString *newFilename = [partialDownloadDir  substringToIndex: [partialDownloadDir length] - 5]; //partialDownloadDir - '.part'
	
	//remove existing file.
	if([fm fileExistsAtPath: newFilename])
		[fm removeFileAtPath: newFilename handler: nil];

	[dataFile closeFile];
	[dataFile release];
	dataFile = nil;
					
	if(makeTS)
	{
		NSString *tsDataFilename = [NSString stringWithFormat: @"%@/data.ts", partialDownloadDir];
		
		//rename data.ts and remove .part directory.
		if([fm movePath: tsDataFilename toPath: newFilename handler: nil] == YES)
			[fm removeFileAtPath: partialDownloadDir handler: nil];
	}
	else
	{
		[fm movePath: partialDownloadDir toPath: newFilename handler: nil];
	}

	
	[trunc release];
	trunc = nil;
	[partialDownloadDir release];
	partialDownloadDir = nil;

	status = WizFileDownload_Complete;

	[delegate downloadFinished: self];
}

-(void) cancelDownload
{
	//stop download.
	if(wizDownload != nil)
		[wizDownload cancel];
	wizDownload = nil;
	
	status = WizFileDownload_Cancelled;
	
	[delegate downloadWasCanceled: self];
}

-(void) pauseDownload
{
	//pause download.
	[wizDownload cancel];
	wizDownload = nil;
	
	status = WizFileDownload_Paused;

	NSLog(@"-Paused- Bytes Downloaded = %llu", bytesDownloaded);

	[delegate downloadWasPaused: self];
}

-(void) resumeDownload
{
	//resume download.
	
	status = WizFileDownload_InProgress;
	
	[self downloadTSPartialChunk: bytesDownloaded];

	[delegate downloadWasResumed: self];
}

-(void) retryDownloadAfterError: (NSTimer *) aTimer
{
	status = WizFileDownload_InProgress;

	if(dataFile == nil)
	{
		[self downloadTrunc];
	}
	else
	{
		if(makeTS)
			[self downloadTSSelectChunk];
		else
			[self downloadSelectChunk];
	}
	
	return;

}

//WizConnectDownloadProtocol delegates
-(void)wizDownload: (WizConnectDownload *) download didReceiveBytes: (int) numBytes
{
	bytesDownloaded += numBytes;
	return;
}

-(void)wizDownload: (WizConnectDownload *) download didFailWithError: (NSError *) error
{
	//FIXME handle errors.
	NSLog(@"ERROR Downloading file!");
	wizDownload = nil;

	if([[error domain] isEqualToString: @"WizErrorDomain"])
	{
		status = WizFileDownload_Error;
		[dataFile closeFile];
		[delegate downloadFailed: self withError: error];
	}
	else
	{
		status = WizFileDownload_Retrying;
		[NSTimer scheduledTimerWithTimeInterval: 2.0 target: self selector: @selector(retryDownloadAfterError:) userInfo: nil repeats: NO];
	}
}

-(void)wizDownloadDidFinishLoading: (WizConnectDownload *) download
{
	wizDownload = nil;
	NSLog(@"Bytes Downloaded = %llu", bytesDownloaded);
	if([download data] == trunc)
	{
		if(makeTS)
			[self downloadTS];
		else
			[self downloadHeader];
	}
	else
	{
		if([dataFilename isEqualToString: @"header"])
			[self downloadStat];
		else if([dataFilename isEqualToString: @"stat"])
			[self downloadWiz];
		else
		{
			if(trunc_index < [wizFile numberOfChunks])
			{
				if(makeTS)
					[self downloadTSNextChunk];
				else
					[self downloadNextChunk];
			}
			else
			{

				[self finishDownload];
			}
		}
	}
}

-(void)failWithErrorTitle: (NSString *)errorTitle errorDesc: (NSString *)errorDesc errorCode: (int) errorCode
{
	status = WizFileDownload_Error;

	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	[userInfo setValue: [NSString stringWithFormat: @"Error: %@", errorTitle] forKey: NSLocalizedDescriptionKey];
	[userInfo setValue: errorDesc forKey:  NSLocalizedRecoverySuggestionErrorKey];
	
	NSError *error = [NSError errorWithDomain: @"WizErrorDomain" code: errorCode userInfo: userInfo];

	[delegate downloadFailed: self withError: error];
}

-(void)dealloc
{
	[wizFile release];
	[delegate release];
	if(partialDownloadDir != nil)
		[partialDownloadDir release];
	if(trunc != nil)
		[trunc release];
	if(wizDownload != nil)
		[wizDownload cancel];
	[localPath release];
	if(rate.timer != nil)
		[rate.timer release];
	[super dealloc];
}


@end
