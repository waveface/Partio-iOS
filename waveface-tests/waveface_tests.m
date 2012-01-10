//
//  wammer_iOS_tests.m
//  wammer-iOS_tests
//
//  Created by jamie on 1/4/12.
//  Copyright (c) 2012 Waveface Inc. All rights reserved.
//

#import "waveface_tests.h"

@implementation NSCalendar (MySpecialCalculations)
-(NSInteger)daysFromDate:(NSDate *) endDate
{
	NSDate *startDate = [NSDate date];
     NSInteger startDay=[self ordinalityOfUnit:NSDayCalendarUnit
          inUnit: NSEraCalendarUnit forDate:startDate];
     NSInteger endDay=[self ordinalityOfUnit:NSDayCalendarUnit
          inUnit: NSEraCalendarUnit forDate:endDate];
     return endDay-startDay;
}
@end

@implementation waveface_tests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testDate
{
	NSTimeInterval secondsPerDay = 24 * 60 * 60;
	NSDate *threeDaysLater = [[NSDate alloc]
							initWithTimeIntervalSinceNow:secondsPerDay*3];
						
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSInteger days = [calendar daysFromDate:threeDaysLater];
	
	STAssertEquals(days, 3, @"3 days");
}

@end
