/*
 *  AppController.m
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

#import "AppController.h"

@implementation AppController
- (id) init {
	self = [super init];
	clickCount = 0;
	index = [[WizIndex alloc] initWithDelegate: self];
	[index retain];
	return self;
}

-(void) awakeFromNib
{
	[table setDataSource: index];
	dlQueue = [WizDLQueue dlQueueWithDelegate: queueController];
	[dlQueue retain];

	[[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (IBAction)connectToWiz:(id)sender {
	WizConnect *wizConnect;
	
	[label setStringValue: [NSString stringWithFormat: @"Click count = %d", clickCount]];
	clickCount++;

	wizConnect = [[WizConnect alloc] initWithHost: [host stringValue] port: [port intValue]];

	[window setTitle: [NSString stringWithFormat: @"WizMac (%@:%d)", [wizConnect host], [wizConnect port]]];

	[index setWizConnect: wizConnect];
	[index getIndex];
	[statusLabel setStringValue: @"Retrieving file list."];
	[statusLabel setHidden: false];
	[spinner setHidden: false];
	[spinner startAnimation: self];
}

- (IBAction)downloadFile:(id)sender
{
	//[index downloadFileAtRow: [table selectedRow]];
	[dlQueue addWizFiles: [index getWizFilesFromIndexSet: [table selectedRowIndexes]]];
	[table deselectAll: self];

	//[queueController addRow: [index getWizFileAtIndex: [table selectedRow]]];
}

//WizIndex delegate methods
-(void) indexUpdated
{
	[table reloadData];
}


-(void) indexHasFinishedUpdating
{
	[statusLabel setHidden: true];
	[spinner stopAnimation: self];
}

@end
