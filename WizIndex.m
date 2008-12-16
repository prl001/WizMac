/*
 *  WizIndex.m
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


#import "WizIndex.h"

@implementation WizIndex


-(id) initWithDelegate:(id)d
{
	self = [super init];

	delegate = d;
	[delegate retain];

	filenames = nil;
	wizFiles = nil;
	wizConnect = nil;

	return self;
}

-(void) setWizConnect: (WizConnect *) wc
{
	[wizConnect release];
	wizConnect = wc;
	[wizConnect retain];
}

-(NSArray *)getWizFiles
{
	return wizFiles;
}

-(NSArray *)getWizFilesFromIndexSet: (NSIndexSet *)indexSet
{
	return [wizFiles objectsAtIndexes: indexSet];
}

-(WizFile *)getWizFileAtIndex: (int) i
{
	return [wizFiles objectAtIndex: i];
}

-(int) count
{
	return curLoadIndex;
}

-(int) totalFiles
{
	if(filenames == nil)
		return 0;

	return [filenames count];
}

-(BOOL) getIndex
{
	index_data = [NSMutableData dataWithLength: 2048];
	[index_data retain];
	
	[wizConnect getFileAsynchronouslyWithPath: @"index.txt" data: index_data delegate: self];

	return true;
}

-(void) loadIndexData
{
	NSArray *lines;
	NSString *line;
	int s, e;
	NSEnumerator *en;
	NSRange range;
	NSString *index_str;

	if(index_data != nil)
	{
		index_str = [[NSString alloc] initWithData: index_data encoding: NSASCIIStringEncoding];
		lines = [index_str componentsSeparatedByString: @"\n"];
		
		[filenames release];
		filenames = [NSMutableArray arrayWithCapacity: [lines count] - 1];
		[filenames retain];

		[wizFiles release];
		wizFiles = [NSMutableArray arrayWithCapacity: [lines count] - 1];
		[wizFiles retain];

		en = [lines objectEnumerator];
		while((line = [en nextObject]))
		{
			if([line length] == 0) //skip empty line.
				continue;
			NSLog(@"raw line = %@",line);
			range = [line rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString: @"|"]];
			if(range.location == NSNotFound) //skip directories
				continue;

			s = range.location + 1;
	
			range = [line rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString: @"/"] options: NSBackwardsSearch];
			e = range.location;
			
			range.location = s;
			range.length = e - s;

			line = [line substringWithRange: range];
			
			[filenames addObject: line];

			curLoadIndex = 0;

			NSLog(@"loc = %d, %d %@",s, e, line);
		}
		[self loadNextWizFile];
	}
	else
	{
		NSLog(@"error: downloading index!");
		return;
	}

	[index_data release];

	return;
}

-(void) loadNextWizFile
{
	NSString *filename;
	NSString *type;
	NSRange range;

	NSString *path;
	
	
	filename = [filenames objectAtIndex: curLoadIndex];
	range = [filename rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString: @"."] options: NSBackwardsSearch];
	range.location++;
	range.length = [filename length] - range.location;
	type = [filename substringWithRange: range];

	path = [NSString stringWithFormat: @"%@/header.%@", [WizConnect urlEncode: filename], type];

	NSLog(@"Path = %@", path);

	header = [NSMutableData dataWithLength: 2048];
	[header retain];
	
	[wizConnect getFileAsynchronouslyWithPath: path data: header maxLength: 2048 delegate: self];
	
}

-(void) loadTrunc
{
	NSString *filename = [filenames objectAtIndex: curLoadIndex];
	NSString *path = [NSString stringWithFormat: @"%@/trunc", [WizConnect urlEncode: filename]];
	
	trunc = [NSMutableData dataWithLength: 3072];
	[trunc retain];
	
	[wizConnect getFileAsynchronouslyWithPath: path data: trunc maxLength: 0 delegate: self];

}

-(void)wizDownload: (WizConnectDownload *) download didReceiveBytes: (int) numBytes
{
	return;
}

-(void)wizDownload: (WizConnectDownload *) download didFailWithError: (NSError *) error
{
	[index_data release];
	index_data = nil;
	[delegate indexUpdateFailedWithError: error];
}

-(void)wizDownloadDidFinishLoading: (WizConnectDownload *) download
{
	NSMutableData *data = [download data];

	if(data == header)
	{
		[self loadTrunc];
	}
	else  if(data == index_data)
	{
		[self loadIndexData];
	}
	else //data == trunc
	{
		WizFile *wizFile;
		NSString *filename = [filenames objectAtIndex: curLoadIndex];
		
		wizFile = [[WizFile alloc] initWithFilename: filename header:header trunc: trunc wizConnect: wizConnect];
		if(wizFile)
		{
			[wizFiles addObject: wizFile];
			[delegate indexUpdated];
		}

		[header release];
		[trunc release];
		header = nil;
		trunc = nil;
		
		curLoadIndex++;
		
		if(curLoadIndex < [filenames count])
		{
			[self loadNextWizFile];
		}
		else
		{
			[delegate indexHasFinishedUpdating];
		}
	}
}

-(void) sortIndexForTableView: (NSTableView *) aTableView
{
	NSArray *selectedFiles = [self getWizFilesFromIndexSet: [aTableView selectedRowIndexes]];
	
	[wizFiles sortUsingDescriptors: [aTableView sortDescriptors]];
	
	if([selectedFiles count] > 0) //reselect rows if required
	{
		[aTableView deselectAll: self];
				
		NSEnumerator *enumerator = [selectedFiles objectEnumerator];
		WizFile *file;
 
		while (file = [enumerator nextObject])
		{
			[aTableView selectRow: [wizFiles indexOfObject: file] byExtendingSelection: YES];
		}
	}

	[aTableView reloadData];
}

//NSTableDataSource methods
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	if(wizFiles)
		return [wizFiles count];

	return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	WizFile *file = [wizFiles objectAtIndex: row];
	
	if ([[tableColumn identifier] isEqualToString:@"svcName"])
	{
		return [file svcName];
	}
	else if ([[tableColumn identifier] isEqualToString:@"evtName"])
	{
		return [file evtName];
	}
	else if ([[tableColumn identifier] isEqualToString:@"date"])
	{
		return [file dateString];
	}
	else if ([[tableColumn identifier] isEqualToString:@"start"])
	{
		return [file startString];
	}
	else if ([[tableColumn identifier] isEqualToString:@"duration"])
	{
		return [file durationString];
	}
	else if ([[tableColumn identifier] isEqualToString:@"filesize"])
	{
		return [file filesizeString];
	}
	else if ([[tableColumn identifier] isEqualToString:@"remoteDir"])
	{
		return [file remoteDir];
	}
	return nil;
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	[self sortIndexForTableView: aTableView];
}

@end
