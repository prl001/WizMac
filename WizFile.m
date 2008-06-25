/*
 *  WizFile.m
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

#import "WizFile.h"

@implementation WizFile

-(id)init
{
	self = [super init];
	return self;
}
-(id)initWithFilename: (NSString *)f header: (NSMutableData *) header trunc: (NSMutableData *) trunc wizConnect: (WizConnect *) wc;
{
	NSRange range;
	self = [self init];
	[filename autorelease];
	filename = [f copy];
	[filename retain];

	wizConnect = wc;
	[wizConnect retain];
	
	range = [filename rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString: @"/"] options: NSBackwardsSearch];
	range.location++;
	range.length = [filename length] - range.location;
	file = [filename substringWithRange: range];
	[file retain];

	NSLog(@"Loading WizFile: %@", filename);
	[self loadHeader: header];
	[self loadTrunc: trunc];

	NSLog(@"svc = %@, evt = %@, mjd = %d, start = %d, duration = %d size = %.2fMB", svcName, evtName, date, start, last * 10 + sec, (float)((double long)filesize / (double long)(1024 * 1024)));

	trunc = nil;

	return self;
}

-(void)loadHeader: (NSMutableData *) header
{
	int date_mjd;
	unsigned char *bytes = (unsigned char *)[header bytes];
	
	[svcName release];
	svcName = [[NSString alloc] initWithBytes: &bytes[0x400] length: strlen((char *)&bytes[0x400]) encoding: NSASCIIStringEncoding];
	[svcName retain];

	[evtName release];
	evtName = [[NSString alloc] initWithBytes: &bytes[0x500] length: strlen((char *)&bytes[0x500]) encoding: NSASCIIStringEncoding];
	[evtName retain];

	date_mjd = EndianU16_LtoN(*(UInt16 *)&bytes[0x600]);
	
	start = EndianU32_LtoN(*(UInt32 *)&bytes[0x604]);
	last = EndianU16_LtoN(*(UInt16 *)&bytes[0x608]);
	sec = EndianU16_LtoN(*(UInt16 *)&bytes[0x60a]);

	[date release];
	date = [NSDate dateWithTimeIntervalSince1970: (date_mjd - 40587) * (24*60*60) + start];
	[date retain];
}

-(void)loadTrunc: (NSMutableData *) trunc
{
	unsigned char *bytes = (unsigned char *)[trunc bytes];
	num_chunks = [trunc length] / 24;
	int i;

	filesize = 0;
	for(i = 0;i < num_chunks;i++)
		filesize += EndianU32_LtoN(*(UInt32 *)&bytes[i * 24 + 0x14]); //size of chunk.

	NSLog(@"filesize = %llu", filesize);
}

-(WizConnect *) wizConnect
{
	return wizConnect;
}

-(NSString *) remotePath
{
	return filename;
}

-(NSString *) localFilenameFromFormatString
{
	NSString *formatString = [[NSUserDefaults standardUserDefaults] objectForKey: @"WizPrefFilenameFormat"];

	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
	
	NSLog(@"format string = %@", formatString);
	
	[dateFormatter setFormatterBehavior: NSDateFormatterBehavior10_4];
	[dateFormatter setTimeZone: [NSTimeZone timeZoneWithAbbreviation: @"UTC"]];
	[dateFormatter setDateFormat: formatString];
	
	NSString *dateString = [dateFormatter stringFromDate: date];
	NSMutableString *formattedString = [NSMutableString stringWithCapacity: [dateString length]];
	[formattedString setString: dateString];	

	[self parseFilenameForSpecialChars: formattedString];

	return [NSString stringWithString: formattedString];
}

-(void) parseFilenameForSpecialChars: (NSMutableString *) s
{
	int i;	

	for(i=0;i < [s length];i++)
	{
		switch([s characterAtIndex: i])
		{
			case '!' : [s replaceCharactersInRange: NSMakeRange(i,1) withString: svcName]; i += ([svcName length] - 1); break;
			case '@' : [s replaceCharactersInRange: NSMakeRange(i,1) withString: evtName]; i += ([evtName length] - 1); break;
		}
	}
}

-(NSString *) file
{
	return file;
}

-(NSString *) svcName
{
	return svcName;
}

-(NSString *) evtName
{
	return evtName;
}

-(NSDate *) date
{
	return date;
}

-(NSString *)dateString
{
	return [date descriptionWithCalendarFormat:@"%a %e-%b-%Y" timeZone: [NSTimeZone timeZoneWithAbbreviation: @"UTC"] locale:nil];
}

-(unsigned int)getDuration
{
	return last * 10 + sec;
}

-(unsigned long long)filesize
{
	return filesize;
}

-(NSString *)filesizeString
{
	if(filesize > (1024 * 1024 * 1024))
		return [NSString stringWithFormat: @"%.1fGB", (float)((long double)filesize / (long double)(1024 * 1024 * 1024))];

	return [NSString stringWithFormat: @"%.1fMB", (float)((long double)filesize / (long double)(1024 * 1024))];
}

-(int) numberOfChunks
{
	return num_chunks;
}

-(NSString *) durationString
{
	int duration = [self getDuration];
	int minutes = floor(duration / 60);
	int seconds = duration % 60;
	
	if(minutes > 0)
		return [NSString stringWithFormat: @"%dmin", minutes];
	
	return [NSString stringWithFormat: @"%dsec", seconds];
}

-(unsigned int)startTime
{
	return start;
}

-(NSString *) startString
{
	bool isPM = false;
	int hour = floor(start / 3600);
	int minute = floor((start % 3600) / 60);
	if(hour > 12)
	{
		isPM = true;
		hour -= 12;
	}
	else if (hour == 0)
		hour = 12;

	return [NSString stringWithFormat: @"%d:%02d%s", hour,minute,(isPM ? "PM" : "AM")];  
}

-(void)dealloc
{
	[super dealloc];
}


@end
