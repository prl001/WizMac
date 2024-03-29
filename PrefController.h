/*
 *  PrefController.m
 *  WizMac
 *
 *  Created by Eric Fry on Wed Jun 4 2008.
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
#import "Prefs.h"

@interface PrefController : NSObject {

IBOutlet NSTextField *downloadDir;
IBOutlet NSTextField *filenameFormat;
IBOutlet NSTextField *filenameFormatWiz;

IBOutlet NSMatrix *fileFormatType;

IBOutlet NSButton *autoConnectOnStartup;

Prefs *prefs;

}
-(id)init;
-(void) awakeFromNib;

-(IBAction) openFileBrowser: (id) sender;
-(IBAction) textfieldUpdated: (id) sender;

- (BOOL)windowShouldClose:(id)window;
-(void) loadPrefs;
-(void) updatePrefs;

-(void)dealloc;

@end
