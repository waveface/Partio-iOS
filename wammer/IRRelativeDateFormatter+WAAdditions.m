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
	
			case NSEraCalendarUnit: return [NSArray arrayWithObjects:
				NSLocalizedString(@"ERA_SINGULAR", nil),
				NSLocalizedString(@"ERA_PLURAL", nil), nil];
			case NSYearCalendarUnit: return [NSArray arrayWithObjects:
				NSLocalizedString(@"YEAR_SINGULAR", nil),
				NSLocalizedString(@"YEAR_PLURAL", nil), nil];
			case NSMonthCalendarUnit: return [NSArray arrayWithObjects:
				NSLocalizedString(@"MONTH_SINGULAR", nil),
				NSLocalizedString(@"MONTH_PLURAL", nil), nil];
			case NSDayCalendarUnit: return [NSArray arrayWithObjects:
				NSLocalizedString(@"DAY_SINGULAR", nil), 
				NSLocalizedString(@"DAY_PLURAL", nil), nil];
			case NSHourCalendarUnit: return [NSArray arrayWithObjects:
				NSLocalizedString(@"HOUR_SINGULAR", nil),
				NSLocalizedString(@"HOUR_PLURAL", nil), nil];
			case NSMinuteCalendarUnit: return [NSArray arrayWithObjects:
				NSLocalizedString(@"MINUTE_SINGULAR", nil),
				NSLocalizedString(@"MINUTE_PLURAL", nil), nil];
			case NSSecondCalendarUnit: return [NSArray arrayWithObjects:
				NSLocalizedString(@"SECOND_SINGULAR", nil),
				NSLocalizedString(@"SECOND_PLURAL", nil), nil];
			case NSWeekCalendarUnit: return [NSArray arrayWithObjects:
				NSLocalizedString(@"WEEK_SINGULAR", nil),
				NSLocalizedString(@"WEEK_PLURAL", nil), nil];
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
