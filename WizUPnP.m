/*
 * WizUPnP.m
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

#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>
#import "WizUPnP.h"

static const char discoverCmdStr[] = "M-SEARCH * HTTP/1.1\r\nHost:239.255.255.250:1900\r\nST:urn:wizpnp-upnp-org:device:pvrtvdevice:1\r\nMan:\"ssdp:discover\"\r\nMX:3\r\n\r\n\r\n";

#define UPNP_GROUP_ADDR "239.255.255.250"

@implementation WizUPnP

-(id)initWithDelegate: (id) d
{
	self = [super init];

	delegate = d;
	[delegate retain];

	sock = -1;
	timer = nil;
	timerCount = 120;

	devices = [NSMutableArray arrayWithCapacity: 1];
	[devices retain];
	
	//[NSThread detachNewThreadSelector: @selector(startDeviceDiscoveryThread:) toTarget: self withObject: nil];
	[self refreshDeviceList];
	
	return self;
}

-(BOOL)isSearching
{
	if(sock != -1)
		return YES;
	
	return NO;
}

-(BOOL)refreshDeviceList
{
	if(sock == -1)
	{
		if([self openSocket] == NO)
			return NO;
	}

	[self sendDiscoverCmd];

	timerCount = 120;
	timer = [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector:@selector(timerCallback:) userInfo: nil repeats: YES];

	[devices removeAllObjects];

	[timer fire];
	
	return YES;
}

-(void)timerCallback: (NSTimer *) aTimer
{
	[self checkForDevices];

	if(timerCount == 0)
	{
		[aTimer invalidate];
		[self closeSocket];
		[delegate WizUPnPFinishedSearching: self];
	}
	else
		timerCount--;
}

-(BOOL)openSocket
{
	struct ip_mreq mreq;
	struct sockaddr_in addr;
	int sock_flags;

	if(sock != -1)
		return NO;

	bzero(&addr, sizeof(addr));

	NSLog(@"Opening socket.");
	sock = socket(AF_INET, SOCK_DGRAM, 0);
	if(sock == -1)
		return NO;

	if((sock_flags = fcntl(sock, F_GETFL, 0)) < 0) 
	{ 
		return NO;
	}
	
	//set socket to non-blocking IO
	if(fcntl(sock, F_SETFL, sock_flags | O_NONBLOCK) < 0) 
	{ 
		return NO;
	} 


	addr.sin_family = AF_INET;
	addr.sin_port = htons(1900);
	addr.sin_addr.s_addr = htonl(INADDR_ANY);
	
	if(bind(sock, (struct sockaddr*)&addr, sizeof(addr)) == -1)
	{
		NSLog(@"Error binding to addr");
		return NO;
	}
	
	mreq.imr_multiaddr.s_addr=inet_addr(UPNP_GROUP_ADDR);
	mreq.imr_interface.s_addr=htonl(INADDR_ANY);
	if (setsockopt(sock,IPPROTO_IP,IP_ADD_MEMBERSHIP,&mreq,sizeof(mreq)) < 0)
	{
		NSLog(@"setsockopt");
		return NO;
	}
	
	setsockopt(sock, IPPROTO_IP, IP_MULTICAST_LOOP, 0, 1);

	return YES;
}

-(BOOL)closeSocket
{
	if(sock != -1)
	{
		close(sock);
		sock = -1;
		
		return YES;
	}
	
	return NO;
}

-(BOOL)sendDiscoverCmd
{
	struct sockaddr_in addr;

	bzero(&addr, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_port = htons(1900);
	addr.sin_addr.s_addr = inet_addr(UPNP_GROUP_ADDR);
	
	NSLog(@"Sent %d bytes to multicast group.", sendto(sock, discoverCmdStr, sizeof(discoverCmdStr), 0, (struct sockaddr *)&addr, sizeof(addr)));

	return YES;
}

-(BOOL) checkForDevices
{
	struct sockaddr_in addr;
	int addrlen;
	char msgbuf[1024];

	bzero(&addr, sizeof(addr));
	addr.sin_family = AF_INET;
	addr.sin_port = htons(1900);
	addr.sin_addr.s_addr = htonl(INADDR_ANY);

	NSString *string;
	NSDictionary *device;


	addrlen=sizeof(addr);
	if(recvfrom(sock,msgbuf,1023,0,(struct sockaddr *) &addr,(socklen_t *)&addrlen) > 0)
	{
		msgbuf[1023] = '\0'; //just in case someone tried to overflow our buf.

		string = [NSString stringWithCString: msgbuf encoding: NSASCIIStringEncoding];

		device = [self parseUPnPResponse: string];
		if(device != nil)
			[self addDevice: device];

		NSLog(@"msg = %@", string);
		return YES;
	}
	
	return NO;
}

-(NSDictionary *)parseUPnPResponse: (NSString *) string
{
	NSString *host = nil;
	NSString *port = nil;
	NSString *device = nil;
	
	NSArray *lines;
	NSString *line;
	NSArray *values;
	lines = [string componentsSeparatedByString: @"\r\n"];
	
	NSEnumerator *e = [lines objectEnumerator];

	for(;line = [e nextObject];)
	{
		NSLog(@"Line = %@", line);
		values = [line componentsSeparatedByString: @": "];
		if([values count] >= 2)
		{
			if([[values objectAtIndex: 0] isEqualToString: @"LOCATION"])
			{

				[self parseLocation: line intoHost: &host port: &port];
			}
			else if([[values objectAtIndex: 0] isEqualToString: @"NICKNAME"])
			{
				device = [values objectAtIndex: 1];
			}
		}
	}
	
	if(host != nil && port != nil && device != nil)
	{
		return [self deviceWithName: device host: host port: port];
	}
	
	return nil;
}

-(BOOL) parseLocation: (NSString *) line intoHost: (NSString **)host port: (NSString **) port
{
	NSArray *address;
	NSRange end = [line rangeOfString: @"/" options: 0 range: NSMakeRange(17, [line length] - 17)];
	line = [line substringWithRange: NSMakeRange(17, end.location - 17)];
	address = [line componentsSeparatedByString: @":"];
	*host = [address objectAtIndex: 0];
	*port = [address objectAtIndex: 1];

	return YES;
}

-(NSDictionary *)deviceWithName: (NSString *) name host: (NSString *) host port: (NSString *) port
{
	return [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects: name, host, port, nil]
		forKeys: [NSArray arrayWithObjects: @"device", @"host", @"port", nil]];
}

-(void) addDevice: (NSDictionary *)newDevice
{
	NSDictionary *device;
	//add device here.
	NSLog(@"Device: name=%@ host=%@ port=%@", [newDevice objectForKey: @"device"], [newDevice objectForKey: @"host"], [newDevice objectForKey: @"port"]);

	if([devices count] > 0)
	{
		NSEnumerator *e = [devices objectEnumerator];

		for(;device = [e nextObject];)
		{
			if([[device objectForKey: @"host"] isEqualToString: [newDevice objectForKey: @"host"]] &&
				[[device objectForKey: @"port"] isEqualToString: [newDevice objectForKey: @"port"]])
			{
				return;
			}
		}
	}
	
	[devices addObject: newDevice];
	[delegate WizUPnPFoundNewDevice: self];

	return;
}

-(NSDictionary *)getDeviceByName: (NSString *) deviceName
{
	return nil;
}

-(NSDictionary *)getDeviceAtRow: (int) row
{
	return [devices objectAtIndex: row];
}

//NSTableDataSource methods
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [devices count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSDictionary *device;

	device = [devices objectAtIndex: row];
	return [device objectForKey: @"device"];
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	//[self sortIndexForTableView: aTableView];
}

@end
