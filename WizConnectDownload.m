/*
 *  WizConnectDownload.m
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

#import "WizConnectDownload.h"


@implementation WizConnectDownload

-(id) initWithURLString: (NSString *) urlString startOffset: (int) startOffset maxLength: (int) maxLength delegate: (id) del
{
	self = [super init];

	urlString = [urlString copy];
	[urlString retain];

	delegate = del;
	[delegate retain];

	NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL: [NSURL URLWithString: urlString]
		cachePolicy: NSURLRequestReloadIgnoringCacheData //NSURLRequestReloadIgnoringLocalAndRemoteCacheData 10.5
		timeoutInterval: 20.0];
	if(maxLength != 0)
	{
		[request setValue: [NSString stringWithFormat: @"bytes=%d-%d", startOffset, startOffset + maxLength-1] forHTTPHeaderField: @"Range"];
		NSLog(@"Partial Download. bytes=%d-%d %d", startOffset, startOffset + maxLength-1, maxLength);
	}
	
	[request setTimeoutInterval: 20.0];
	
	con = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	[con retain];

	stopDownloading = NO;

	file = nil;
	data = nil;

	[self retain];

	return self;
}

-(id) initWithURLString: (NSString *) urlString data: (NSMutableData *) d maxLength: (int) maxLength delegate: (id) del
{
	self = [self initWithURLString: urlString startOffset: 0 maxLength: maxLength delegate: del];

	data = d;
	[data retain];

	return self;
}

-(id) initWithURLString: (NSString *) urlString localFile: (NSFileHandle *) f startOffset: (int) startOffset maxLength: (int) maxLength delegate: (id) del
{
	self = [self initWithURLString: urlString startOffset: startOffset maxLength: maxLength delegate: del];

	file = f;
	[file retain];

	return self;
}

- (NSMutableData *) data
{
	return data;
}

- (void) cancel
{
	stopDownloading = YES;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if(data)
		[data setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d
{
	if(stopDownloading == YES)
	{
		NSLog(@"Download stopped!");
		[connection cancel];
		[self release];
		return;
	}
	@try
	{
		if(file)
			[file writeData: d];
		else
			[data appendData:d];

		[delegate wizDownload: self didReceiveBytes: [d length]];
	}
	@catch (NSException *ne)
	{
		NSLog(@"Exception: %@ Reason: %@", [ne name], [ne reason]);
		NSArray *reasonItems = [[ne reason] componentsSeparatedByString: @": "];
		
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
		[userInfo setValue: @"Error: WizConnectDownload" forKey: NSLocalizedDescriptionKey];
		[userInfo setValue: [reasonItems lastObject] forKey:  NSLocalizedRecoverySuggestionErrorKey];
	
		NSError *error = [NSError errorWithDomain: @"WizErrorDomain" code: WizConnectDownloadError_WritingData userInfo: userInfo];
		[connection cancel];
		[delegate wizDownload: self didFailWithError: error];
		[self release];
	}
	
	 return; 
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	// inform the user
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
	
	[delegate wizDownload: self didFailWithError: error];
	[self release];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if(data)
		NSLog(@"Succeeded! Received %d bytes of data",[data length]);
	else
		NSLog(@"Succeeded!");

	[delegate wizDownloadDidFinishLoading: self];
    [self release];
}

-(void)dealloc
{
	[file release];
	[con release];
	[url_str release];
	[data release];
	[delegate release];
	[super dealloc];
}

@end
