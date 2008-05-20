/*
 *  AppController.h
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
#import <AppKit/NSTableView.h>

#import "WizIndex.h"
#import "WizDLQueue.h"
#import "QueueController.h"

@interface AppController : NSObject <WizIndexDelegate> {
IBOutlet NSTextField *label;
IBOutlet NSTextField *host;
IBOutlet NSTextField *port;
IBOutlet NSTableView *table;
IBOutlet NSProgressIndicator *spinner;
IBOutlet NSTextField *statusLabel;
IBOutlet NSWindow *window;
IBOutlet QueueController *queueController;

int clickCount;
WizIndex *index;
WizDLQueue *dlQueue;

}
-(void) awakeFromNib;
- (IBAction)connectToWiz:(id)sender;
- (IBAction)downloadFile:(id)sender;

//WizIndex delegate methods
-(void) indexUpdated;
-(void) indexHasFinishedUpdating;

@end
