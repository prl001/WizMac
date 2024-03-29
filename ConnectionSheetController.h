/*
 * ConnectionSheetController.h
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

#import <Cocoa/Cocoa.h>

#import "WizUPnP.h"

@interface ConnectionSheetController : NSObject <WizUPnPDelegate> {

IBOutlet NSWindow *sheet;
IBOutlet NSTextField *hostField;
IBOutlet NSTextField *portField;
IBOutlet NSTableView *table;
IBOutlet NSTabView *tabView;

IBOutlet NSTextField *searchLabel;
IBOutlet NSProgressIndicator *searchSpinner;

WizUPnP *upnp;

id delegate;
NSDictionary *deviceRequest;
}

-(void) requestDeviceConnection: (NSString *) deviceName delegate: (id) d;
-(void) deviceRequestTimeoutCallback: (NSTimer *) aTimer;
-(void) removeDeviceRequest;

-(void) showSheet:( NSWindow *)window withDelegate: (id) d;
-(IBAction)closeSheet: (id) sender;

-(void)updateSearchLabel;

-(IBAction)refreshUPnPList: (id) sender;

-(IBAction)connect: (id) sender;

-(void) didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

//WizUPnPDelegate methods
-(void) WizUPnPFinishedSearching: (WizUPnP *)aUpnp;
-(void) WizUPnPFoundNewDevice: (WizUPnP *)aUpnp;
@end
