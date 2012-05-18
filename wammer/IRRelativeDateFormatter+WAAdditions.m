//
//  IRRelativeDateFormatter+WAAdditions.m
//  wammer
//
//  Created by jamie on 5/18/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "IRRelativeDateFormatter+WAAdditions.h"

@implementation IRRelativeDateFormatter (WAAdditions)

+ (NSArray *) stringRepresentationFormatterStringsforCalendarUnit:(NSCalendarUnit)inCalendarUnit past:(BOOL)inRepresentingDateInThePast {

//	This could be locale specific, but we are not dealing with it now

//	if (inRepresentingDateInThePast) {
	
		switch (inCalendarUnit) {
	
			case NSEraCalendarUnit: return [NSArray arrayWithObjects:@"%d era", @"%d eras", nil];
			case NSYearCalendarUnit: return [NSArray arrayWithObjects:@"%d year", @"%d years", nil];
			case NSMonthCalendarUnit: return [NSArray arrayWithObjects:
				NSLocalizedString(@"MONTH_NOUN", nil),
				NSLocalizedString(@"MONTH_PLURAL", nil), nil];
			case NSDayCalendarUnit: return [NSArray arrayWithObjects:
				NSLocalizedString(@"DAY_NOUN", nil), 
				NSLocalizedString(@"DAY_PLURAL", nil), nil];
			case NSHourCalendarUnit: return [NSArray arrayWithObjects:@"%d hour", @"%d hours", nil];
			case NSMinuteCalendarUnit: return [NSArray arrayWithObjects:@"%d minute", @"%d minutes", nil];
			case NSSecondCalendarUnit: return [NSArray arrayWithObjects:@"%d second", @"%d seconds", nil];
			case NSWeekCalendarUnit: return [NSArray arrayWithObjects:@"%d week", @"%d weeks", nil];
			case NSWeekdayCalendarUnit: return [NSArray arrayWithObjects:@"%d workday", @"%d workdays", nil];
			case NSWeekdayOrdinalCalendarUnit: return [NSArray arrayWithObjects:@"%d Ordinal Workday", @"%d Ordinal Workdays", nil];
			case NSQuarterCalendarUnit: return [NSArray arrayWithObjects:@"%d Quarter", @"%d Quarters", nil];
			default: return nil;
		
		}
	
//	} else {
	
	
//	}

}

+ (NSString *) wrappedStringRepresentationForString:(NSString *)inString representedDateTimepoint:(IRDateTimepoint)timePoint {

	switch (timePoint) {
  case IRDateTimepointPast:
		return [NSString stringWithFormat:NSLocalizedString(@"DATE_AGO", @"in relative date format"), inString];
  case IRDateTimepointNow:
		return inString;
  case IRDateTimepointFuture:
		return [NSString stringWithFormat:NSLocalizedString(@"DATE_AFTER", @"in relative date format"), inString];
	}
	
}

@end
