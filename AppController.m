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
	NSArray *keys = [NSArray arrayWithObjects: @"WizIP", @"WizPort", nil];
	NSArray *objects = [NSArray arrayWithObjects: @"192.168.1.4", @"49152", nil];
	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjects: objects forKeys: keys];
 
    [defaults registerDefaults:appDefaults];
}

-(void) awakeFromNib
{
	[table setDataSource: index];
	dlQueue = [WizDLQueue dlQueueWithDelegate: queueController];
	[dlQueue retain];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[host setStringValue: [defaults objectForKey:@"WizIP"]];
	[port setStringValue: [defaults objectForKey:@"WizPort"]];

	[[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (IBAction)connectToWiz:(id)sender {
	WizConnect *wizConnect;

	wizConnect = [[WizConnect alloc] initWithHost: [host stringValue] port: [port intValue]];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setObject:[host stringValue] forKey:@"WizIP"];
	[defaults setObject:[port stringValue] forKey:@"WizPort"];

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
