/*
 * WizUPnP.h
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

@interface WizUPnP : NSObject {
NSMutableArray *devices;
int sock;
int timerCount;
NSTimer *timer;

id delegate;
}

-(id)initWithDelegate: (id) d;

-(BOOL) isSearching;
-(BOOL) refreshDeviceList;
-(void) timerCallback: (NSTimer *) aTimer;
-(BOOL) openSocket;
-(BOOL) closeSocket;
-(BOOL) sendDiscoverCmd;
-(BOOL) checkForDevices;

-(NSDictionary *)parseUPnPResponse: (NSString *) string;
-(BOOL) parseLocation: (NSString *) line intoHost: (NSString **)host port: (NSString **) port;
-(NSDictionary *)deviceWithName: (NSString *) name host: (NSString *) host port: (NSString *) port;
-(void) addDevice: (NSDictionary *)device;

-(NSDictionary *)getDeviceByName: (NSString *) deviceName;
-(NSDictionary *)getDeviceAtRow: (int) row;

//NSTableDataSource methods
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors;

@end

@protocol WizUPnPDelegate
-(void) WizUPnPFinishedSearching: (WizUPnP *)aUpnp;
-(void) WizUPnPFoundNewDevice: (WizUPnP *)aUpnp;
@end

