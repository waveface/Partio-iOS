//
//  NSDate+WAAdditions.h
//  wammer
//
//  Created by Shen Steven on 10/6/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (WAAdditions)

- (NSDate *)dayEnd;
- (NSDate *)dayBegin;
- (NSDate *)dateOfPreviousMonth;
- (NSDate *)dateOfFollowingMonth;
- (NSDate *)dateOfPreviousWeek;
- (NSDate *)dateOfFollowingWeek;
- (NSDate *)dateOfPreviousDay;
- (NSDate *)dateOfFollowingDay;
- (NSDate *)dateOfPreviousNumOfDays:(NSUInteger)numOfDays;
- (NSDate *)dateOfNextNumOfDays:(NSUInteger)numOfDays;

- (NSString *) dayString;
- (NSString *) yearString;
- (NSString *) localizedMonthShortString;
- (NSString *) localizedMonthFullString;
- (NSString *) localizedWeekDayShortString;
- (NSString *) localizedWeekDayFullString;

extern BOOL (^isSameDay) (NSDate *, NSDate *);

@end
