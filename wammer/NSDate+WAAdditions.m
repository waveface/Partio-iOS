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
  
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *dateComponents = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSTimeZoneCalendarUnit)
				         fromDate:self];
  dateComponents.day += 1;
  return [calendar dateFromComponents:dateComponents];
  
}

- (NSDate *)dayBegin {
  
  NSCalendar *calendar = [NSCalendar currentCalendar];
  
  NSDateComponents *dateComponents = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSTimeZoneCalendarUnit)
				         fromDate:self];
  return [calendar dateFromComponents:dateComponents];
  
}

- (NSDate *)dateOfPreviousMonth {
  
  NSCalendar *calendar = [NSCalendar currentCalendar];
  
  NSDateComponents *dateComponents = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit)
				         fromDate:self];
  dateComponents.month -= 1;
  return [calendar dateFromComponents:dateComponents];
  
}

- (NSDate *)dateOfFollowingMonth {
  
  NSCalendar *calendar = [NSCalendar currentCalendar];
  
  NSDateComponents *dateComponents = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit)
				         fromDate:self];
  dateComponents.month += 1;
  return [calendar dateFromComponents:dateComponents];
  
}

- (NSDate *)dateOfPreviousWeek {
  
  NSCalendar *calendar = [NSCalendar currentCalendar];
  
  NSDateComponents *dateComponents = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
				         fromDate:self];
  dateComponents.day -= 7;
  return [calendar dateFromComponents:dateComponents];
  
}

- (NSDate *)dateOfFollowingWeek {
  
  NSCalendar *calendar = [NSCalendar currentCalendar];
  
  NSDateComponents *dateComponents = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
				         fromDate:self];
  dateComponents.day += 7;
  return [calendar dateFromComponents:dateComponents];
  
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

BOOL (^isSameDay) (NSDate *, NSDate *) = ^ (NSDate *d1, NSDate *d2) {
  
  NSCalendar* calendar = [NSCalendar currentCalendar];
  unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
  NSDateComponents* comp1 = [calendar components:unitFlags fromDate:d1];
  NSDateComponents* comp2 = [calendar components:unitFlags fromDate:d2];
  if ( [comp1 day] == [comp2 day] &&
      [comp1 month] == [comp2 month] &&
      [comp1 year]  == [comp2 year])
    return YES;
  return NO;
  
};

@end
