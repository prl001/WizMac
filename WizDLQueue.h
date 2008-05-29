/*
 *  WizDLQueue.h
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

#import "WizFile.h"
#import "WizFileDownload.h"

@protocol WizDLQueueDelegate
-(void) addRow:(WizFileDownload *) f;
-(void) updateRow:(WizFileDownload *) f;
-(void) removeRow:(WizFileDownload *) f;
@end

@interface WizDLQueue : NSObject {

id delegate;
NSMutableArray *queue;
WizFileDownload *currentDownload;
}

+(id) dlQueueWithDelegate: (id) d;

-(id) initWithDelegate: (id) d;

-(bool) fileIsDownloading;

-(void) addWizFiles: (NSArray *) files;
-(bool) removeWizFile: (WizFileDownload *) file;

-(void) startNextDownload;

//WizFileDownloadProtocol
-(void) downloadFinished: (WizFileDownload *) file;
-(void) downloadWasCanceled: (WizFileDownload *) file;
-(void) downloadWasPaused: (WizFileDownload *) file;

-(void) dealloc;



@end
