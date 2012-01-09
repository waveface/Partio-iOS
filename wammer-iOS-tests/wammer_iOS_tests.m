//
//  wammer_iOS_tests.m
//  wammer-iOS_tests
//
//  Created by jamie on 1/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "wammer_iOS_tests.h"

@implementation NSCalendar (MySpecialCalculations)
-(NSInteger)daysWithinEraFromDate:(NSDate *) startDate toDate:(NSDate *) endDate
{
     NSInteger startDay=[self ordinalityOfUnit:NSDayCalendarUnit
          inUnit: NSEraCalendarUnit forDate:startDate];
     NSInteger endDay=[self ordinalityOfUnit:NSDayCalendarUnit
          inUnit: NSEraCalendarUnit forDate:endDate];
     return endDay-startDay;
}
@end

@implementation wammer_iOS_tests

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
	NSInteger days = [calendar daysWithinEraFromDate:[NSDate date] toDate:threeDaysLater];
	
	STAssertEquals(days, 3, @"3 days");
}

@end
