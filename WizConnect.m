/*
 *  WizConnect.m
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

#import "WizConnect.h"


@implementation WizConnect

-(id) initWithHost: (NSString *) h port: (int) p
{
	self = [super init];
	
	[self setHost: h];
	[self setPort: p];

	return self;
}

-(void) setHost: (NSString *) h
{
	[host autorelease];
	host = [h copy];
	[host retain];
}

-(void) setPort: (int) p
{
	port = p;
}

-(NSString *) host
{
	return host;
}

-(int) port
{
	return port;
}


//simple API that encodes reserved characters according to:
//RFC 3986
//http://tools.ietf.org/html/rfc3986
+(NSString *) urlEncode: (NSString *) url
{
//WARNING! I have removed @"/", @"%2F"
    NSArray *escapeChars = [NSArray arrayWithObjects:@" ", @";" , @"?" , @":" ,
                                                        @"@" , @"&" , @"=" , @"+" ,
                                                        @"$" , @"," , @"[" , @"]",
                                                        @"#", @"!", @"'", @"(", 
                                                        @")", @"*", nil];

    NSArray *replaceChars = [NSArray arrayWithObjects:@"%20", @"%3B" , @"%3F" ,
                                                        @"%3A" , @"%40" , @"%26" ,
                                                        @"%3D" , @"%2B" , @"%24" ,
                                                        @"%2C" , @"%5B" , @"%5D", 
                                                        @"%23", @"%21", @"%27",
                                                        @"%28", @"%29", @"%2A", nil];

    int len = [escapeChars count];

    NSMutableString *temp = [url mutableCopy];

    int i;
    for(i = 0; i < len; i++)
    {

        [temp replaceOccurrencesOfString: [escapeChars objectAtIndex:i]
                                    withString:[replaceChars objectAtIndex:i]
                                    options:NSLiteralSearch
                                    range:NSMakeRange(0, [temp length])];
    }

    NSString *out = [NSString stringWithString: temp];

    return out;
}

-(NSString *) getURLString: (NSString *) path
{
	return [NSString stringWithFormat: @"http://%@:%d/%@", host, port, path];
}

-(NSData *) getFileSynchronouslyWithPath: (NSString *) path
{
	NSString *url_str;
	NSData *data = nil;
	NSURLResponse *resp;
	NSError *err;
	NSMutableURLRequest *request;
	url_str = [self getURLString: path];
	NSLog(url_str);

	request = [NSMutableURLRequest  requestWithURL: [NSURL URLWithString: url_str]];
	[request setTimeoutInterval: 30];

	if([NSURLConnection canHandleRequest: request] == YES)
		data = [NSURLConnection sendSynchronousRequest: request returningResponse: &resp error: &err];

	return data;
}

-(WizConnectDownload *) getFileAsynchronouslyWithPath: (NSString *) path data: (NSMutableData *) data delegate: (id) delegate;
{
	return [self getFileAsynchronouslyWithPath: path data: data maxLength: 0 delegate: delegate];
}

-(WizConnectDownload *) getFileAsynchronouslyWithPath: (NSString *) path data: (NSMutableData *) data maxLength: (int) maxLength delegate: (id) delegate
{
	NSString *url_str = [self getURLString: path];

	WizConnectDownload *dl = [[WizConnectDownload alloc] initWithURLString: url_str data:data maxLength:maxLength delegate:delegate];

	return dl;
}

-(WizConnectDownload *) getFileAsynchronouslyWithPath: (NSString *) path appendToLocalFile: (NSFileHandle *)f startOffset: (int) startOffset maxLength: (int) maxLength delegate: (id) delegate
{
	NSString *url_str = [self getURLString: path];

	WizConnectDownload *dl = [[WizConnectDownload alloc] initWithURLString: url_str localFile:f startOffset: startOffset maxLength:maxLength delegate:delegate];

	return dl;
}

@end
