/*
 *  WizIndex.h
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
#import "WizFile.h"

@protocol WizIndexDelegate
-(void) indexUpdated;
-(void) indexHasFinishedUpdating;
-(void) indexUpdateFailedWithError: (NSError *) error;
@end

@interface WizIndex : NSObject <WizConnectDownloadDelegate> {
NSMutableArray *filenames;
NSMutableArray *wizFiles;
int curLoadIndex;
WizConnect *wizConnect;


NSMutableData *index_data;
NSMutableData *header;
NSMutableData *trunc;

id delegate;
}

-(id)initWithDelegate:(id)d;
-(void) setWizConnect: (WizConnect *) wc;
-(NSArray *)getWizFiles;
-(NSArray *)getWizFilesFromIndexSet: (NSIndexSet *)indexSet;
-(WizFile *)getWizFileAtIndex: (int) i;

-(BOOL) getIndex;

-(void) loadIndexData;
-(void) loadNextWizFile;
-(void) loadTrunc;

// WizConnectDownloadDelegate
-(void)wizDownload: (WizConnectDownload *) download didReceiveBytes: (int) numBytes;
-(void)wizDownload: (WizConnectDownload *) download didFailWithError: (NSError *) error;
-(void)wizDownloadDidFinishLoading: (WizConnectDownload *) download;

// NSTableDataSource
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors;
@end
