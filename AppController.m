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
	index = [[WizIndex alloc] initWithDelegate: self];
	[index retain];
	return self;
}

+ (void)initialize{
 
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary
        dictionaryWithObject:@"" forKey:@"WizIP"];
 
    [defaults registerDefaults:appDefaults];
}

-(void) awakeFromNib
{
	[table setDataSource: index];
	dlQueue = [WizDLQueue dlQueueWithDelegate: queueController];
	[dlQueue retain];

	[host setStringValue: [[NSUserDefaults standardUserDefaults] objectForKey:@"WizIP"]];
	
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (IBAction)connectToWiz:(id)sender {
	WizConnect *wizConnect;

	wizConnect = [[WizConnect alloc] initWithHost: [host stringValue] port: [port intValue]];

	[[NSUserDefaults standardUserDefaults] setObject:[host stringValue] forKey:@"WizIP"];

	[window setTitle: [NSString stringWithFormat: @"WizMac (%@:%d)", [wizConnect host], [wizConnect port]]];

	[index setWizConnect: wizConnect];
	if([index getIndex] == TRUE)
	{
		[statusLabel setStringValue: @"Retrieving file list."];
		[statusLabel setHidden: false];
		[spinner setHidden: false];
		[spinner startAnimation: self];
	}
	else
	{
		[statusLabel setStringValue: @"Error connecting to host."];
		[statusLabel setHidden: false];
		[spinner setHidden: false];
	}
}

- (IBAction)downloadFile:(id)sender
{
	[dlQueue addWizFiles: [index getWizFilesFromIndexSet: [table selectedRowIndexes]]];
	[table deselectAll: self];
}

//WizIndex delegate methods
-(void) indexUpdated
{
	[index sortIndexForTableView: table];
}

-(void) indexUpdateFailedWithError: (NSError *) error
{
	NSAlert *alert = [NSAlert alertWithMessageText: @"Error Connecting" defaultButton: @"Ok" alternateButton: nil otherButton: nil informativeTextWithFormat: @"Error: %@", @"Time Out!"];
	[statusLabel setHidden: true];
	[spinner setHidden: true];
	[spinner stopAnimation: self];
			
	[alert beginSheetModalForWindow: window modalDelegate: self didEndSelector: @selector(alertDidEnd:returnCode:contextInfo:)  contextInfo: nil];
}

-(void) indexHasFinishedUpdating
{
	[statusLabel setHidden: true];
	[spinner stopAnimation: self];
}

//NSAlert selector
- (void) alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	return;
}

@end
