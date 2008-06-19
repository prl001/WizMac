/*
 *  WizConnectDownload.h
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

#import <Cocoa/Cocoa.h>

#define WizConnectDownloadError_WritingData 1

@interface WizConnectDownload : NSObject {
NSString *url_str;
NSURLConnection *con;
NSMutableData *data;
id delegate;
NSFileHandle *file;
bool stopDownloading;
}

-(id) initWithURLString: (NSString *) urlString data: (NSMutableData *) d maxLength: (int) maxLength delegate: (id) del;
-(id) initWithURLString: (NSString *) urlString localFile: (NSFileHandle *) f startOffset: (int) startOffset maxLength: (int) maxLength delegate: (id) del;

- (NSMutableData *) data;

- (void) cancel;

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

- (void)dealloc;

@end

@protocol WizConnectDownloadDelegate
-(void)wizDownload: (WizConnectDownload *) download didReceiveBytes: (int) numBytes;
-(void)wizDownload: (WizConnectDownload *) download didFailWithError: (NSError *) error;
-(void)wizDownloadDidFinishLoading: (WizConnectDownload *) download;
@end
