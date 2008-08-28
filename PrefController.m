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

#import "PrefController.h"


@implementation PrefController

-(id) init
{
	self = [super init];

	prefs = [[Prefs alloc] init];
	[prefs retain];

	return self;
}

-(Prefs *) prefs
{
	return prefs;
}

-(void) awakeFromNib
{
	[self loadPrefs];
}

-(IBAction) openFileBrowser: (id) sender
{
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles: NO];
	[panel setCanChooseDirectories: YES];
	[panel setAllowsMultipleSelection: NO];

	if([panel runModalForDirectory: nil file: nil] == NSOKButton)
	{
		NSArray *files = [panel filenames];
		if([files count] > 0)
		{
			NSLog(@"Directory = %@",[files objectAtIndex: 0]);
			[downloadDir setStringValue: [files objectAtIndex: 0]];
			[self updatePrefs];
		}
	}
}

-(IBAction) textfieldUpdated: (id) sender
{
	[self updatePrefs];
}

- (BOOL)windowShouldClose:(id)window
{
	[self updatePrefs];

	return YES;
}

-(void) loadPrefs
{
	[downloadDir setStringValue: [prefs downloadDir]];
	[filenameFormat setStringValue: [prefs filenameFormat]];
	[filenameFormatWiz setStringValue: [prefs filenameFormatWiz]];
	[fileFormatType selectCellWithTag: [prefs useTSFormat] ? 1 : 0];
	[autoConnectOnStartup setState: [prefs autoConnectOnStartup] ? NSOnState : NSOffState];
}

-(void) updatePrefs
{
	[prefs setDownloadDir: [downloadDir stringValue]];
	[prefs setFilenameFormat: [filenameFormat stringValue]];
	[prefs setFilenameFormatWiz: [filenameFormatWiz stringValue]];
	[prefs setUseTSFormat: [[fileFormatType selectedCell] tag] == 1 ? YES : NO];
	[prefs setAutoConnectOnStartup: [autoConnectOnStartup state] == NSOnState ? YES : NO];
}

-(void)dealloc
{
	[prefs release];
	[super dealloc];
}

@end
