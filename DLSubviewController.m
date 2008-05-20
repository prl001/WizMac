//
//  DLSubviewController.m
//  SubviewTableViewTester
//
//  Created by Joar Wingfors on Tue Dec 02 2003.
//  Copyright (c) 2003 joar.com. All rights reserved.
//

#import "DLSubviewController.h"

@implementation DLSubviewController

+ (id) controllerWithWizFileDownload: (WizFileDownload *) f
{
    return [[[self alloc] initWithWizFileDownload: f] autorelease];
}

- (id) initWithWizFileDownload: (WizFileDownload *)f
{
    if ((self = [super init]) != nil)
    {
        if (![NSBundle loadNibNamed: @"DownloadSubview" owner: self])
        {
            [self release];
            self = nil;
        }
    }
    
	bytesDownloaded = 0;

	wizFileDownload = f;
	[wizFileDownload retain];

	if(wizFileDownload != nil)
	{
		WizFile *wizFile = [wizFileDownload wizFile];

		NSLog([wizFile file]);
		[fileLabel setStringValue: [NSString stringWithFormat: @"%@: %@", [wizFile svcName], [wizFile evtName]]];
		
		[fileLabel1 setStringValue: [NSString stringWithFormat:@"%@ - %@ - %@",
			[wizFile dateString], 
			[wizFile startString],
			[wizFile durationString]]];

		if([wizFileDownload status] == WizFileDownload_InProgress)
		{
			downloadTimer = [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector:@selector(downloadUpdateProgress:) userInfo: nil repeats: YES];
			[downloadTimer retain];
		}
		else
			[self downloadUpdateProgress: nil];
	}
    return self;
}

-(void) awakeFromNib
{
	//[fileLabel setStringValue: [wizFile file]];
	[infoLabel setStringValue: @""];
	[progressIndicator setDoubleValue: 0];
	
}

-(void)downloadUpdateProgress: (NSTimer *) aTimer
{
	[progressIndicator setDoubleValue: [wizFileDownload percentageDownloaded]];

	//long double bytesPerSecond = [wizFileDownload bytesDownloaded] - bytesDownloaded;
	long double bytesPerSecond = [wizFileDownload avgDownloadRate];
	//bytesPerSecond = bytesPerSecond * 2;
	bytesDownloaded = [wizFileDownload bytesDownloaded];
	double kbps = (double)bytesPerSecond / 1024;

	unsigned int secondsToGo = (unsigned int)(([wizFileDownload filesize] - bytesDownloaded) / bytesPerSecond);
	NSString *eta;
	
	if(secondsToGo > (60 * 60 * 24))
		eta = [NSString stringWithFormat: @"%dd %dh", (unsigned int)floor(secondsToGo / (60 * 60 * 24)), (secondsToGo % (60 * 60 * 24)) / (60 * 60)];
	else if(secondsToGo > (60 * 60))
		eta = [NSString stringWithFormat: @"%dh %dm", (unsigned int)floor(secondsToGo / (60 * 60)), (secondsToGo % (60 * 60)) / 60];
	else if(secondsToGo > 60)
		eta = [NSString stringWithFormat: @"%dm %ds", (unsigned int)floor(secondsToGo / 60), secondsToGo % 60];
	else
		eta = [NSString stringWithFormat: @"%ds", secondsToGo];
	
	if([wizFileDownload status] == WizFileDownload_InProgress)
		[infoLabel setStringValue: [NSString stringWithFormat: @"%.1Lf/%.1LfMB  (%.1fKB/s) ETA %@", ((double long)bytesDownloaded / (1024 * 1024)), (long double)[wizFileDownload filesize] / (long double)(1024 * 1024),(float)kbps,eta]];
	else // WizFileDownload_Paused
	{
		[infoLabel setStringValue: [NSString stringWithFormat: @"%.1Lf/%.1LfMB (Paused)", ((double long)bytesDownloaded / (1024 * 1024)), ((double long)[wizFileDownload filesize] / (1024 * 1024))]];
		// change to refresh icon.
		[pauseButton setImage: [NSImage imageNamed: @"action_refresh.png"]];
	}
	return;
}

-(IBAction) cancelDownload: (id) sender
{
	[wizFileDownload cancelDownload];
}

-(IBAction) pauseDownload: (id) sender
{
	if([wizFileDownload status] == WizFileDownload_Paused)
		[wizFileDownload resumeDownload];
	else
		[wizFileDownload pauseDownload];
}

- (void) dealloc
{
	if(downloadTimer != nil)
		[downloadTimer release];
    [subview release];
    [wizFileDownload release];
    [super dealloc];
}

- (NSView *) view
{
    return subview;
}

- (WizFileDownload *) wizFileDownload
{
	return wizFileDownload;
}


@end
