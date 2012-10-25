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

- (NSString *) dayString {
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"dd"];
	return [formatter stringFromDate:self];
	
}

- (NSString *) localizedMonthShortString {
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"MMM"];
	return [formatter stringFromDate:self];
	
}

- (NSString *) localizedMonthFullString {

	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"MMMM"];
	return [formatter stringFromDate:self];
	
}

- (NSString *) localizedWeekDayShortString {

	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"EEE"];
	return [formatter stringFromDate:self];

}


- (NSString *) localizedWeekDayFullString {
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"EEEE"];
	return [formatter stringFromDate:self];
	
}

@end
