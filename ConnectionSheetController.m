/*
 * ConnectionSheetController.m
 *  WizMac
 *
 *  Created by Eric Fry on Sun Jun 22 2008.
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

#import "ConnectionSheetController.h"
#import "WizConnect.h"

@implementation ConnectionSheetController

-(id) init
{
	self = [super init];

	upnp = [[WizUPnP alloc] initWithDelegate: self];
	[upnp retain];

	[NSBundle loadNibNamed: @"ConnectionSheet" owner: self];

	return self;
}

-(void) awakeFromNib
{
	[table setDataSource: upnp];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[hostField setStringValue: [defaults objectForKey:@"WizPrefIP"]];
	[portField setStringValue: [defaults objectForKey:@"WizPrefPort"]];

}

-(void) showSheet:( NSWindow *)window withDelegate: (id) d
{
	delegate = d;
	[delegate retain];

	[NSApp beginSheet: sheet
		modalForWindow: window
		modalDelegate: self
		didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		contextInfo: nil];
	
	[self updateSearchLabel];
}

-(void)updateSearchLabel
{
	if([upnp isSearching])
	{
		[searchLabel setHidden: false];
		[searchSpinner setHidden: false];
		[searchSpinner startAnimation: self];
	}
	else
	{
		[searchLabel setHidden: true];
		[searchSpinner setHidden: true];
		[searchSpinner stopAnimation: self];
	}
}

-(IBAction)refreshUPnPList: (id) sender
{
	[upnp refreshDeviceList];
	[self updateSearchLabel];
	[table reloadData];
}

-(IBAction)connect: (id) sender
{
	NSTabViewItem *item = [tabView selectedTabViewItem];
	if([[item identifier] isEqualToString: @"manual"])
	{
		[delegate newConnectionWithName: @"" host: [hostField stringValue] port: [portField intValue]];
	}
	else
	{
		if([table selectedRow] == -1) //you must make a selection.
			return;

		NSDictionary *device = [upnp getDeviceAtRow: [table selectedRow]];
		[delegate newConnectionWithName: [device objectForKey: @"device"] host: [device objectForKey: @"host"] port: [[device objectForKey: @"port"] intValue]];
	}

//	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

//	[defaults setObject:[host stringValue] forKey:@"WizPrefIP"];
//	[defaults setObject:[port stringValue] forKey:@"WizPrefPort"];

	[self closeSheet: self];
}

-(IBAction)closeSheet: (id) sender
{
	[NSApp endSheet: sheet];
}

- (void)didEndSheet:(NSWindow *)aSheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [aSheet orderOut:self];
	[delegate release];
	delegate = nil;
}

-(void) WizUPnPFinishedSearching: (WizUPnP *)upnp
{
	[self updateSearchLabel];
}

-(void) WizUPnPFoundNewDevice: (WizUPnP *)upnp
{
	[table reloadData];
}

-(void)dealloc
{
	[upnp release];
	[super dealloc];
}

@end
