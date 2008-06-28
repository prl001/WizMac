/*
 *  WizFile.h
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
#import "WizConnect.h"

@interface WizFile : NSObject {

 NSString *dir, *filename, *file, *svcName, *evtName;
 NSString *type;
 NSDate *date;
 unsigned long start;
 int last;
 int sec;
 int trunc_index;
 int num_chunks;
 unsigned long long filesize;
 WizConnect *wizConnect;
 //NSMutableData *trunc;
}

-(id)init;
-(id)initWithFilename: (NSString *)f header: (NSMutableData *) header trunc: (NSMutableData *) trunc wizConnect: (WizConnect *) wc;
-(void)loadHeader: (NSMutableData *) header;
-(void)loadTrunc: (NSMutableData *) trunc;

-(WizConnect *) wizConnect;
-(NSString *) remotePath;
-(NSString *) localFilenameFromFormatString;
-(void) parseFilenameForSpecialChars: (NSMutableString *) s;
-(NSString *) file;
-(NSString *) type;
-(NSString *) svcName;
-(NSString *) evtName;
-(NSDate *) date;
-(NSString *)dateString;
-(unsigned long long)filesize;
-(NSString *)filesizeString;
-(int) numberOfChunks;


-(unsigned int)getDuration;
-(NSString *) durationString;
-(unsigned int)startTime;
-(NSString *) startString;

@end