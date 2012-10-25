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

- (NSString *) dayString;
- (NSString *) localizedMonthShortString;
- (NSString *) localizedMonthFullString;
- (NSString *) localizedWeekDayShortString;
- (NSString *) localizedWeekDayFullString;

@end
