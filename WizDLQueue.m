/*
 *  WizDLQueue.m
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

#import "WizDLQueue.h"


@implementation WizDLQueue

+(id) dlQueueWithDelegate: (id) d
{
	return [[WizDLQueue alloc] initWithDelegate: d];
}

-(id) initWithDelegate: (id) d
{
	self = [super init];
	
	delegate = d;
	[delegate retain];
	
	queue = [NSMutableArray arrayWithCapacity: 10];
	[queue retain];

	currentDownload = nil;

	return self;
}

-(bool) fileIsDownloading
{
	if(currentDownload != nil && [currentDownload isDownloading])
		return YES;
	
	return NO;
}

-(void) addWizFiles: (NSArray *) files
{
	//[queue addObjectsFromArray: files];
	NSString *downloadDir = [[[NSUserDefaults standardUserDefaults] objectForKey: @"WizPrefDownloadDir"] stringByExpandingTildeInPath];
	NSEnumerator *e = [files objectEnumerator];
	
	WizFile *file;
	WizFileDownload *wizFileDownload;
	
	for(;file = [e nextObject];)
	{
		wizFileDownload = [WizFileDownload wizFileDownload: file Delegate: self];
		[wizFileDownload setDownloadPath: downloadDir];
		
		if([wizFileDownload checkForExistingDownload] == YES)
		{
			if([delegate shouldOverwriteExistingDownload: wizFileDownload] == NO)
				continue;
		}

		if([wizFileDownload checkForExistingPartialDownload] == YES)
		{
			
			switch([delegate shouldResumePartialDownload: wizFileDownload])
			{
				case WizDLResumePartial_No : [wizFileDownload resumeFromPartialDownload: NO]; break;
				case WizDLResumePartial_Cancel : continue;
			}
		}

		[queue addObject: wizFileDownload];
		[delegate addRow: wizFileDownload];
	}

	if([self fileIsDownloading] == NO)
	{
		[self startNextDownload];
	}
}

-(bool) removeWizFile: (WizFileDownload *) wizFileDownload
{
	unsigned int index = [queue indexOfObject: wizFileDownload];
	if(index == NSNotFound)
		return false;

	if(wizFileDownload == currentDownload)
	{
		[self startNextDownload];
	}

	[queue removeObject: wizFileDownload];
	[delegate removeRow: wizFileDownload];

	//we are removing the currentDownload and there is no new download to start.
	//set the current Download pointer to the end of the list.
	if(wizFileDownload == currentDownload)
	{
		currentDownload = [queue lastObject];
	}
	return true;
}

-(void) startNextDownload
{
	unsigned int newIndex = 0;
	
	if(currentDownload != nil)
		newIndex = [queue indexOfObject: currentDownload] + 1;

	if(newIndex < [queue count])
	{
		currentDownload = [queue objectAtIndex: newIndex];
		[currentDownload download];

		[delegate updateRow: currentDownload];
		// start download
		// update queue controller to show download view.
	}

}

-(void) downloadFinished: (WizFileDownload *) file
{
	//update queue controller to show download complete!
	[delegate updateRow: file];
	[self startNextDownload];
}

-(void) downloadFailed: (WizFileDownload *) file withError: (NSError *) error
{
	[NSApp presentError: error];
	[delegate updateRow: file];
}

-(void) downloadWasPaused: (WizFileDownload *) file
{
	//[self removeWizFile: file];
	//[self startNextDownload];

	NSLog(@"Download Paused!");

	[delegate updateRow: file];
}

-(void) downloadWasResumed: (WizFileDownload *) file
{
	NSLog(@"Download Resumed!");

	[delegate updateRow: file];

}

-(void) downloadWasCanceled: (WizFileDownload *) file
{
	NSLog(@"Download Canceled!");
	
	[self removeWizFile: file];
}

-(void) dealloc
{
	[delegate release];
	[queue release];
	[super dealloc];
}

@end
