//
//  QueueController.m
//  SubviewTableViewTester
//
//  Created by Joar Wingfors on Tue Dec 02 2003.
//  Copyright (c) 2003 joar.com. All rights reserved.
//

#import "QueueController.h"

#import "DLSubviewController.h"
#import "QueuedSubviewController.h"


@implementation QueueController

// The rows in the table view
- (NSMutableArray *) subviewControllers
{
    if (subviewControllers == nil)
    {
        subviewControllers = [[NSMutableArray alloc] init];
    }
    
    return subviewControllers;
}

- (void) awakeFromNib
{
	NSArray *a = [subviewTableView tableColumns];

    // Creating the SubviewTableViewController
	//subviewTableColumn = [
	// objectAtIndex:0];
	subviewTableColumn = [a objectAtIndex: 0];
	NSLog(@"Array length = %d identifier = %@", [a count], [subviewTableColumn identifier]);
    tableViewController = [[SubviewTableViewController controllerWithViewColumn: subviewTableColumn] retain];
    [tableViewController setDelegate: self];

    NSLog(@"datasource = %@", [subviewTableView dataSource]);
	NSLog(@"delegate = %@", [subviewTableView delegate]);
    // Make sure that the buttons have the right state
    //[self validateButtons];
}

- (void) dealloc
{
    [tableViewController release];
    [subviewControllers release];
    
    [super dealloc];
}

- (void)addRow:(WizFileDownload *) f
{
    NSIndexSet *selectedRows = [subviewTableView selectedRowIndexes];
    unsigned int index = [selectedRows lastIndex];
    if (index != NSNotFound)
    {
        [[self subviewControllers] insertObject: [QueuedSubviewController controllerWithWizFileDownload: f] atIndex: (index + 1)];
    }
    else
    {
        [[self subviewControllers] addObject: [QueuedSubviewController controllerWithWizFileDownload: f]];
    }
    [tableViewController reloadTableView];
}

- (void)updateRow:(WizFileDownload *) f
{
	unsigned int index = [self findWizFileIndex: f];
	
	if(index != NSNotFound)
	{
		[[self subviewControllers] removeObjectAtIndex: index];

		if([f isDownloading])
			[[self subviewControllers] insertObject: [DLSubviewController controllerWithWizFileDownload: f] atIndex: index];
		else
			[[self subviewControllers] insertObject: [QueuedSubviewController controllerWithWizFileDownload: f] atIndex: index];

		[tableViewController reloadTableView];
	}
}

- (void) removeRow:(WizFileDownload *) f
{
    unsigned int index = [self findWizFileIndex: f];
    if (index != NSNotFound)
    {
		[[self subviewControllers] removeObjectAtIndex: index];
        [tableViewController reloadTableView];
    }
}

-(unsigned int) findWizFileIndex: (WizFileDownload *)file
{
	NSArray *wizFiles = [[self subviewControllers] valueForKey: @"wizFileDownload"];
	return [wizFiles indexOfObject: file];
}

// Methods from SubviewTableViewControllerDataSourceProtocol

- (NSView *) tableView:(NSTableView *) tableView viewForRow:(int) row
{
    return [[[self subviewControllers] objectAtIndex: row] view];
}

// Methods from NSTableViewDelegate category

- (void) tableViewSelectionDidChange:(NSNotification *) notification
{
    //[self validateButtons];
}

// Methods from NSTableDataSource protocol

- (int) numberOfRowsInTableView:(NSTableView *) tableView
{
    return [[self subviewControllers] count];
}

- (id) tableView:(NSTableView *) tableView objectValueForTableColumn:(NSTableColumn *) tableColumn row:(int) row
{
    id obj = nil;
/*    
    if (tableColumn == rowNumberTableColumn)
    {
        obj = [NSNumber numberWithInt: row];
    }
*/    
    return obj;
}

@end
