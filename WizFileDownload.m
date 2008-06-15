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
	tsFile = nil;
	delegate = nil;
	wizDownload = nil;
	trunc = nil;
	resumeFromPartialDownload = YES;
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
	if(status == WizFileDownload_InProgress || status == WizFileDownload_Paused)
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

-(void) downloadTS
{
	NSFileManager *fm = [NSFileManager defaultManager];
	trunc_index = 0;

	dir = [NSString stringWithFormat: @"%@/%@.part", localPath, [wizFile localFilenameFromFormatString]];
	[dir retain];
	
	if([fm fileExistsAtPath: dir] == YES)
	{
		if(resumeFromPartialDownload == NO)
		{
			if([fm removeFileAtPath: dir handler: nil] == YES)
				[fm createDirectoryAtPath: dir attributes: nil]; //create a new fresh dir
		}
	}
	else
		[fm createDirectoryAtPath: dir attributes: nil];

	//save trunc file
	NSLog([NSString stringWithFormat: @"%@/trunc", dir]);
	if([trunc writeToFile: [NSString stringWithFormat: @"%@/trunc", dir] atomically: YES] == NO)
		NSLog(@"ARgh!");

	NSString *datafile = [NSString stringWithFormat: @"%@/data.ts", dir];

	if([fm fileExistsAtPath: datafile] == NO)
	{
		//make sure file exists
		//FIXME find a better way to make an empty file.
		FILE *f = fopen([datafile cString], "w");
		fclose(f);
	}
	
	tsFile = [NSFileHandle fileHandleForUpdatingAtPath: datafile];
	[tsFile retain];

	//unsigned char *bytes = (unsigned char *)[trunc bytes];

	bytesDownloaded = 0;

	downloadStartDate = [NSDate date];

	[self downloadSelectChunk];

	[self startDLRateCalc];
		
}

-(void) downloadSelectChunk
{
	unsigned long long dataFileSize = [tsFile seekToEndOfFile];
	if(dataFileSize == [wizFile filesize])
	{
		return [self finishDownload];
	}
	
	if(dataFileSize > 0)
	{
		[self downloadPartialChunk: dataFileSize];
	}
	else
		[self downloadNextChunk];

	return;
}

//resume downloading a partial chunk
-(void) downloadPartialChunk: (unsigned long long) fsize
{
	NSString *path;
	long double tmp_index = (long double)fsize / WIZ_CHUNKSIZE;
	trunc_index = (int)floor((double)tmp_index);
	int num_chunks = [wizFile numberOfChunks];
	int startOffset;
	int i;
	unsigned long long trunc_size = 0;
	unsigned int chunk_size;
	unsigned int length;

	unsigned char *bytes = (unsigned char *)[trunc bytes];

	bytesDownloaded = fsize;
		
	for(i=0;i < num_chunks;i++)
	{
		chunk_size = EndianU32_LtoN(*(UInt32 *)&bytes[i * 24 + 0x14]);
		if((trunc_size + chunk_size) > fsize)
		{
			trunc_index = i;
			startOffset = (int)(fsize - trunc_size);
			length = chunk_size - startOffset;
			startOffset += EndianU32_LtoN(*(UInt32 *)&bytes[i * 24 + 0xC]); //offset in chunk.
			break;
		}
		trunc_size += chunk_size;
	}

	int chunk_number = EndianU16_LtoN(*(UInt16 *)&bytes[trunc_index * 24 + 0x8]);

	path = [NSString stringWithFormat: @"%@/%04d", [WizConnect urlEncode: [wizFile remotePath]], chunk_number];

	NSLog(@"Downloading: %@ fsize = %qu startOffset = %d chunk_size = %d", path, fsize, startOffset, chunk_size);
	
	//data = [NSMutableData dataWithLength: 33554432];
	
	wizDownload = [[wizFile wizConnect] getFileAsynchronouslyWithPath: path appendToLocalFile: tsFile startOffset: startOffset maxLength: length delegate: self];
	trunc_index++;
}

-(void) downloadNextChunk
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
	
	wizDownload = [[wizFile wizConnect] getFileAsynchronouslyWithPath: path appendToLocalFile: tsFile startOffset: startOffset maxLength: length delegate: self];
	trunc_index++;
}

-(void) finishDownload
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *datafile = [NSString stringWithFormat: @"%@/data.ts", dir];
	NSString *newTSFile = [dir  substringToIndex: [dir length] - 5]; //dir - '.part'
	

	//remove existing file.
	if([fm fileExistsAtPath: newTSFile])
		[fm removeFileAtPath: newTSFile handler: nil];

	//rename data.ts and remove .part directory.
	if([fm movePath: datafile toPath: newTSFile handler: nil] == YES)
		[fm removeFileAtPath: dir handler: nil];
	
	[trunc release];
	trunc = nil;
	[dir release];
	dir = nil;

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
	
	[self downloadPartialChunk: bytesDownloaded];

	[delegate downloadWasResumed: self];
}

-(void) retryDownloadAfterError
{
	if(tsFile == nil)
	{
		[self downloadTrunc];
	}
	else
	{
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
	[delegate downloadFailed: self withError: error];
}

-(void)wizDownloadDidFinishLoading: (WizConnectDownload *) download
{
	wizDownload = nil;
	NSLog(@"Bytes Downloaded = %llu", bytesDownloaded);
	if([download data] == trunc)
	{
		[self downloadTS];
	}
	else
	{
		if(trunc_index < [wizFile numberOfChunks])
			[self downloadNextChunk];
		else
		{
			[tsFile closeFile];
			[tsFile release];
			tsFile = nil;
			[self finishDownload];
		}
	}
}

-(void)dealloc
{
	[wizFile release];
	[delegate release];
	if(dir != nil)
		[dir release];
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
