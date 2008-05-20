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

-(void) downloadWithDownloadPath: (NSString *) aPath 
{
	NSString *truncPath;
	if([self isDownloading] == YES)
		return;



	status = WizFileDownload_InProgress;

	localPath = [aPath copy];
	[localPath retain];

	trunc = [NSMutableData dataWithLength: 4028];
	[trunc retain];

	truncPath = [NSString stringWithFormat: @"%@/trunc", [WizConnect urlEncode: [wizFile remotePath]]];
NSLog(truncPath);

	wizDownload = [[wizFile wizConnect] getFileAsynchronouslyWithPath: truncPath data: trunc delegate: self];

	return;
}

-(void) downloadTS
{
//	NSString *desktop = [[NSString stringWithString: @"~/Desktop"] stringByExpandingTildeInPath];
	NSFileManager *fm = [NSFileManager defaultManager];
	trunc_index = 0;

	dir = [NSString stringWithFormat: @"%@/%@.ts.part", localPath, [wizFile file]];
	[dir retain];
	
	if([fm fileExistsAtPath: dir] == NO)
	{
		[fm createDirectoryAtPath: dir attributes: nil];
	}
	
	//save trunc file
	NSLog([NSString stringWithFormat: @"%@/trunc", dir]);
	if([trunc writeToFile: [NSString stringWithFormat: @"%@/trunc", dir] atomically: YES] == NO)
		NSLog(@"ARgh!");

	NSString *datafile = [NSString stringWithFormat: @"%@/data.ts", dir];

	if([fm fileExistsAtPath: datafile] == NO)
	{
		//make sure file exists
		FILE *f = fopen([datafile cString], "w");
		fclose(f);
	}
	
	tsFile = [NSFileHandle fileHandleForUpdatingAtPath: datafile];
	[tsFile retain];

	//unsigned char *bytes = (unsigned char *)[trunc bytes];

	bytesDownloaded = 0;

	downloadStartDate = [NSDate date];

	NSDictionary * fileAttributes = [fm fileAttributesAtPath:datafile traverseLink:NO];
	NSNumber *dataFileSize = [fileAttributes objectForKey: NSFileSize];
	if([dataFileSize unsignedLongLongValue] > 0)
	{
		[self downloadPartialChunk: [dataFileSize unsignedLongLongValue]];
	}
	else
		[self downloadNextChunk];

	[self startDLRateCalc];

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

-(void)downloadDidReceiveBytes: (int) num_bytes
{
	bytesDownloaded += num_bytes;
	return;
}

-(void)downloadOfData: (NSMutableData *) data didFailWithError: (NSError *) error
{
	//FIXME handle errors.
	NSLog(@"ERROR Downloading file!");
	wizDownload = nil;
}

-(void)downloadDidFinishLoading: (NSMutableData *) data
{
	wizDownload = nil;
	NSLog(@"Bytes Downloaded = %llu", bytesDownloaded);
	if(data == trunc)
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
