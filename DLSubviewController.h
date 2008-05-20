//
//  DLSubviewController.h

//
//  Created by Joar Wingfors on Tue Dec 02 2003.
//  Copyright (c) 2003 joar.com. All rights reserved.
//

/*****************************************************************************

DLSubviewController

Overview:

The DLSubviewController is a very simple class. It is the controller object for
the custom views used in the table. It provides the view, and answers to
actions methods from the view or the table view controller.

*****************************************************************************/

#import <AppKit/AppKit.h>
#import "WizFileDownload.h"

@interface DLSubviewController : NSObject
{
    @private

    IBOutlet NSView *subview;
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSTextField *fileLabel;
    IBOutlet NSTextField *fileLabel1;
    IBOutlet NSTextField *infoLabel;
	IBOutlet NSButton *pauseButton;

	WizFileDownload *wizFileDownload;
    BOOL isAnimating;
	NSTimer *downloadTimer;
	unsigned long bytesDownloaded;
}

- (id) initWithWizFileDownload: (WizFileDownload *)f;

// Convenience factory method
+ (id) controllerWithWizFileDownload: (WizFileDownload *) f;



// The view displayed in the table view
- (NSView *) view;
- (WizFileDownload *) wizFileDownload;

-(void)downloadUpdateProgress: (NSTimer *) aTimer;

-(IBAction) cancelDownload: (id) sender;
-(IBAction) pauseDownload: (id) sender;

@end
