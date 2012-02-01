//
//  WATests_iOS.m
//  wammer-iOS-Tests
//
//  Created by jamie on 1/4/12.
//  Copyright (c) 2012 Waveface Inc. All rights reserved.
//

#import "WATests_iOS.h"

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

@implementation WATests_iOS

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

- (void)testBitOperation
{
  __block unsigned char tileMap = 0b00000000;
	__block unsigned char nextTile = 0b00000000;
  
  BOOL (^usableTile)(unsigned char) = ^ (unsigned char bitMask) {

    for (unsigned char i = 0b10000000; i > 0; i >>= 1)
      if ( !(tileMap & i) ){
        nextTile = i;
        break;
      }  
		return (BOOL) ( !(tileMap & bitMask) && (bitMask & nextTile) ) ;
	};
  
  STAssertTrue( usableTile(0b11001100), @"should be true");
  STAssertFalse( usableTile(0b00110011), @"should be false");
  
}

@end
