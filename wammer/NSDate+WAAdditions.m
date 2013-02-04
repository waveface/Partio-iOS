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

+ (NSDateFormatter *) sharedDayStringFormatter {
  
  static NSDateFormatter *dateFormatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd"];
  });
  return dateFormatter;

}

- (NSString *) dayString {
  
  return [[[self class] sharedDayStringFormatter] stringFromDate:self];
  
}

+ (NSDateFormatter *) sharedYearStringFormatter {
  
  static NSDateFormatter *dateFormatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy"];
  });
  return dateFormatter;
  
}

- (NSString *) yearString {

  return [[[self class] sharedYearStringFormatter] stringFromDate:self];

}

+ (NSDateFormatter *) sharedMonthShortStringFormatter {
  
  static NSDateFormatter *dateFormatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM"];
  });
  return dateFormatter;
  
}

- (NSString *) localizedMonthShortString {
  
  return [[[self class] sharedMonthShortStringFormatter] stringFromDate:self];
  
}

+ (NSDateFormatter *) sharedMonthFullStringFormatter {
  
  static NSDateFormatter *dateFormatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM"];
  });
  return dateFormatter;
  
}

- (NSString *) localizedMonthFullString {
  
  return [[[self class] sharedMonthFullStringFormatter] stringFromDate:self];
  
}

+ (NSDateFormatter *) sharedWeekDayShortStringFormatter {
  
  static NSDateFormatter *dateFormatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE"];
  });
  return dateFormatter;
  
}

- (NSString *) localizedWeekDayShortString {
  
  return [[[self class] sharedWeekDayShortStringFormatter] stringFromDate:self];
  
}

+ (NSDateFormatter *) sharedWeekDayFullStringFormatter {
  
  static NSDateFormatter *dateFormatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEEE"];
  });
  return dateFormatter;
  
}

- (NSString *) localizedWeekDayFullString {
  
  return [[[self class] sharedWeekDayFullStringFormatter] stringFromDate:self];
  
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
