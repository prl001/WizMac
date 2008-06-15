/*
 *  WizFileDownload.h
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

#import <Cocoa/Cocoa.h>
#import "WizConnect.h"
#import "WizFile.h"

typedef enum 
{
	WizFileDownload_New, 
	WizFileDownload_Queued, 
	WizFileDownload_InProgress,
	WizFileDownload_Paused,
	WizFileDownload_Complete,
	WizFileDownload_Cancelled
} WizFileDownloadStatus;

#define WIZ_NUM_SAMPLES 10

typedef struct
{
	unsigned int sample[WIZ_NUM_SAMPLES];
	short sampleIndex;
	unsigned long long bytesDownloaded;
	NSTimer *timer;
} WizFileDownloadRate;

@interface WizFileDownload : NSObject {

 WizFile *wizFile;
 NSString *dir, *localPath;
 NSFileHandle *tsFile;
 
 BOOL resumeFromPartialDownload;
 
 int trunc_index;
 //int num_chunks;
 unsigned long long bytesDownloaded;
 WizConnect *wizConnect;
 WizConnectDownload *wizDownload;
 NSMutableData *trunc;
 id delegate;
 
 WizFileDownloadStatus status;
 WizFileDownloadRate rate;

 NSDate *downloadStartDate;
}

+(WizFileDownload *) wizFileDownload: (WizFile *) aWizFile Delegate: (id) d;

-(id)initWithWizFile: (WizFile *) aWizFile Delegate: (id) d;

-(void) initDLRateCalc;

-(void) resumeFromPartialDownload: (BOOL) answer;

-(void) startDLRateCalc;
- (void) updateDLRateCalc: (NSTimer *) aTimer;
-(unsigned int) avgDownloadRate;

-(WizFile *) wizFile;
-(WizFileDownloadStatus) status;

-(unsigned long long) filesize;
-(unsigned long long) bytesDownloaded;
-(NSString *)bytesDownloadedString;
-(double) percentageDownloaded;
-(bool) isDownloading;

-(bool) checkForExistingDownload;
-(bool) checkForExistingPartialDownload;

-(bool) setDownloadPath: (NSString *) aPath;
-(NSString *) downloadPath;
-(NSString *) partialDownloadDir;
-(NSString *) completeDownloadFilename;

-(bool) downloadWithDownloadPath: (NSString *) aPath;
-(bool) download;

-(void) downloadTrunc;
-(void) downloadTS;
-(void) downloadSelectChunk;
-(void) downloadPartialChunk: (unsigned long long) fsize;
-(void) downloadNextChunk;

-(void) finishDownload;
-(void) cancelDownload;
-(void) pauseDownload;
-(void) resumeDownload;
-(void) retryDownloadAfterError;

// WizConnectDownloadDelegate
-(void)wizDownload: (WizConnectDownload *) download didReceiveBytes: (int) numBytes;
-(void)wizDownload: (WizConnectDownload *) download didFailWithError: (NSError *) error;
-(void)wizDownloadDidFinishLoading: (WizConnectDownload *) download;

@end


@protocol WizFileDownloadProtocol
-(void) downloadWasPaused: (WizFileDownload *)dl;
-(void) downloadWasResumed: (WizFileDownload *)dl;
-(void) downloadWasCanceled: (WizFileDownload *)dl;
-(void) downloadFailed: (WizFileDownload *)dl withError: (NSError *) error;
-(void) downloadFinished: (WizFileDownload *)dl;
@end
