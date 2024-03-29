//
//  QueuedSubviewController.m
//  SubviewTableViewTester
//
//  Created by Joar Wingfors on Tue Dec 02 2003.
//  Copyright (c) 2003 joar.com. All rights reserved.
//

#import "QueuedSubviewController.h"

@implementation QueuedSubviewController

+ (id) controllerWithWizFileDownload: (WizFileDownload *) f
{
    return [[[self alloc] initWithWizFileDownload: f] autorelease];
}

- (id) initWithWizFileDownload: (WizFileDownload *)f
{
    if ((self = [super init]) != nil)
    {
        if (![NSBundle loadNibNamed: @"QueuedSubview" owner: self])
        {
            [self release];
            self = nil;
        }
    }
    
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
			
		switch([wizFileDownload status])
		{
			case WizFileDownload_Complete : [self showShowInFinderMenuItem];
				[infoLabel setStringValue: [NSString stringWithFormat: @"Done - Downloaded %@",[wizFileDownload bytesDownloadedString]]];
				break;

			case WizFileDownload_Queued : [infoLabel setStringValue: @"Queued"]; break;
			
			case WizFileDownload_Error : [infoLabel setStringValue: @"Error downloading file!"]; break;

		}
	}

    return self;
}

-(void) showShowInFinderMenuItem
{
	NSMenuItem *item = [contextualMenu itemWithTag: 0];
	[item setEnabled: YES];
}

-(void) awakeFromNib
{
	//[fileLabel setStringValue: [wizFile file]];
	[infoLabel setStringValue: @"Queued"];
	
}

-(IBAction) cancelDownload: (id) sender
{
	[wizFileDownload cancelDownload];
}

-(IBAction) showInFinder: (id) sender
{
	NSString *fullPath = [wizFileDownload completeDownloadFilename];
	[[NSWorkspace sharedWorkspace] selectFile: fullPath inFileViewerRootedAtPath: nil];
}

- (void) dealloc
{
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
