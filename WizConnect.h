/*
 *  WizConnect.h
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
#import "WizConnectDownload.h"

@interface WizConnect : NSObject {
NSString *host;
int port;

}
-(id) initWithHost: (NSString *) h port: (int) p;
-(void) setHost: (NSString *) h;
-(void) setPort: (int) p;
-(NSString *) host;
-(int) port;

+(NSString *) urlEncode: (NSString *) url;

-(NSData *) getFileSynchronouslyWithPath: (NSString *) path;
-(WizConnectDownload *) getFileAsynchronouslyWithPath: (NSString *) path data: (NSMutableData *) data delegate: (id) delegate;
-(WizConnectDownload *) getFileAsynchronouslyWithPath: (NSString *) path data: (NSMutableData *) data maxLength: (int) maxLength delegate: (id) delegate;
-(WizConnectDownload *) getFileAsynchronouslyWithPath: (NSString *) path appendToLocalFile: (NSFileHandle *)f startOffset: (int) startOffset maxLength: (int) maxLength delegate: (id) delegate;

@end
