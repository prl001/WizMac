/*
 *  Prefs.m
 *  WizMac
 *
 *  Created by Eric Fry on Thr Jun 5 2008.
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

#import "Prefs.h"


@implementation Prefs

-(id)init
{
	self = [super init];

	defaults = [NSUserDefaults standardUserDefaults];
	return self;
}

+(void)initialize
{
	//load defaults
	NSArray *keys = [NSArray arrayWithObjects: @"WizPrefUPnPName", @"WizPrefIP", @"WizPrefPort", @"WizPrefDownloadDir", @"WizPrefDownloadUseTSFormat", @"WizPrefFilenameFormat", @"WizPrefFilenameFormatWiz", @"WizPrefAutoConnectOnStartup", nil];
	NSArray *objects = [NSArray arrayWithObjects: @"", @"192.168.1.4", @"49152", @"~/Desktop", @"YES", @"!_@_yyyyMMdd_HHmm.'ts'", @"!_@_yyyyMMdd_HHmm.#", @"NO", nil];
	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjects: objects forKeys: keys];
 
    [defaults registerDefaults:appDefaults];

}

-(void)setDownloadDir: (NSString *)aDownloadDir
{
	
	[defaults setObject: aDownloadDir forKey:@"WizPrefDownloadDir"];
}

-(NSString *) downloadDir
{
	return [defaults objectForKey:@"WizPrefDownloadDir"];
}

-(void)setUseTSFormat: (BOOL) val
{
	[defaults setBool: val forKey: @"WizPrefDownloadUseTSFormat"];
}

-(BOOL)useTSFormat
{
	return [defaults boolForKey: @"WizPrefDownloadUseTSFormat"];
}

-(void)setFilenameFormat: (NSString *)aFilenameFormat
{	
	[defaults setObject: aFilenameFormat forKey:@"WizPrefFilenameFormat"];
}

-(void)setFilenameFormatWiz: (NSString *)aFilenameFormat
{	
	[defaults setObject: aFilenameFormat forKey:@"WizPrefFilenameFormatWiz"];
}

-(NSString *) filenameFormat
{
	return [defaults objectForKey:@"WizPrefFilenameFormat"];
}

-(NSString *) filenameFormatWiz
{
	return [defaults objectForKey:@"WizPrefFilenameFormatWiz"];
}

-(void)setAutoConnectOnStartup: (BOOL) val
{
	[defaults setBool: val forKey:@"WizPrefAutoConnectOnStartup"];
}

-(BOOL)autoConnectOnStartup
{
	return [defaults boolForKey:@"WizPrefAutoConnectOnStartup"];
}

-(void)dealloc
{
	[super dealloc];
}

@end
