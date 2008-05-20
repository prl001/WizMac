//
//  QueueController.h
//  SubviewTableViewTester
//
//  Created by Joar Wingfors on Tue Dec 02 2003.
//  Copyright (c) 2003 joar.com. All rights reserved.
//

/*****************************************************************************

QueueController

Overview:

This is the standard application controller and NSApplication delegate.
It is also the delegate and data source of the table view, by proxy via the
SubviewTableViewController.

*****************************************************************************/

#import <Foundation/Foundation.h>
#import "WizFileDownload.h"
#import "SubviewTableViewController.h"

@interface QueueController : NSObject < SubviewTableViewControllerDataSourceProtocol >
{
    @private
    
    IBOutlet NSTableView *subviewTableView;
    NSTableColumn *subviewTableColumn;
    IBOutlet NSButton *addRowButton;
    IBOutlet NSButton *removeRowButton;
    IBOutlet NSButton *toggleAnimationButton;
    
    SubviewTableViewController *tableViewController;
    NSMutableArray *subviewControllers;
}

- (void) addRow:(WizFileDownload *) f;
- (void) updateRow:(WizFileDownload *) f;
- (void) removeRow:(WizFileDownload *) f;

-(unsigned int) findWizFileIndex: (WizFileDownload *)file;

- (IBAction) toggleAnimation:(id) sender;

@end
