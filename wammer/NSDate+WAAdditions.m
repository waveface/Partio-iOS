//
//  NSDate+WAAdditions.m
//  wammer
//
//  Created by Shen Steven on 10/6/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "NSDate+WAAdditions.h"

@implementation NSDate (WAAdditions)

- (NSDate *)dayEnd {
	
	NSCalendar *cal = [NSCalendar currentCalendar];

	NSDateComponents *dcomponents = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:self];
	[dcomponents setDay:[dcomponents day] + 1];
	return [cal dateFromComponents:dcomponents];

}

- (NSDate *)dayBegin {

	NSCalendar *cal = [NSCalendar currentCalendar];

	NSDateComponents *dcomponents = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:self];
	return [cal dateFromComponents:dcomponents];

}


@end
