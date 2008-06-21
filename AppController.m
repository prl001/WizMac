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

-(void) awakeFromNib
{
	[table setDataSource: index];
	dlQueue = [WizDLQueue dlQueueWithDelegate: queueController];
	[dlQueue retain];
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	//automatically connect to last known host. If auto connect on startup is selected in the config.
	if([defaults boolForKey:@"WizPrefAutoConnectOnStartup"] == YES)
	{
	//	[self connectToWiz: self]; //FIXME we need to handle connect from last know host. either upnp or manual.
	}
	else
		[self showConnectionSheet:self];
}

- (IBAction)downloadFile:(id)sender
{
	[dlQueue addWizFiles: [index getWizFilesFromIndexSet: [table selectedRowIndexes]]];
	[table deselectAll: self];
}

-(IBAction)showConnectionSheet:(id)sender
{
	[connectionSheetContoller showSheet: window withDelegate: self];
}

//WizIndex delegate methods
-(void) indexUpdated
{
	[statusLabel setStringValue: [NSString stringWithFormat: @"Retrieving file list. (%d/%d)", [index count], [index totalFiles]]];
	[spinner setDoubleValue: (double)[index count] / (double)[index totalFiles]];
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
	[spinner setHidden: true];
}

//NSAlert selector
- (void) alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	return;
}

//WizConnectProtocol
-(void)newConnectionWithName: (NSString *) name host: (NSString *) host port: (int) port
{
	WizConnect *wizConnect;

	wizConnect = [[WizConnect alloc] initWithHost: host port: port];

	[window setTitle: [NSString stringWithFormat: @"WizMac - %@ (%@:%d)", name, host, port]];

	[index setWizConnect: wizConnect];
	if([index getIndex] == TRUE)
	{
		[statusLabel setStringValue: @"Retrieving file list."];
		[statusLabel setHidden: false];
		[spinner setHidden: false];
		[spinner startAnimation: self];
		
		//save default connection values
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject: name forKey:@"WizPrefDeviceName"];
		[defaults setObject: host forKey:@"WizPrefIP"];
		[defaults setObject: [NSString stringWithFormat: @"%d", port] forKey:@"WizPrefPort"];
	}
	else
	{
		[statusLabel setStringValue: @"Error connecting to host."];
		[statusLabel setHidden: false];
		[spinner setHidden: false];
	}
}

@end
