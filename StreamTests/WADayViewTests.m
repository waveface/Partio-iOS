//
//  WADayViewTests.m
//  wammer
//
//  Created by jamie on 11/10/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADayViewTests.h"
#import "WADayViewController.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "WADataStore.h"

#import "WAPhotoStreamViewController.h"
#import "WATimelineViewController.h"

@interface WADayViewController (UnitTesting)

@property (nonatomic, readwrite, strong) NSMutableDictionary *daysControllers;
@property (nonatomic, readwrite, strong) NSMutableArray *days;

- (id) controllerAtPageIndex: (NSUInteger) index;

@end

@interface WAPhotoStreamViewController (UnitTesting)

@property (strong, nonatomic) NSArray *photos;
@property (strong, nonatomic) NSMutableArray *layout;

@end

@implementation WADayViewTests {
  WADayViewController *eventDayViewController;
  WADayViewController *photoDayViewController;
}

- (void)setUp {
  [MagicalRecord cleanUp];
  [MagicalRecord setupCoreDataStackWithStoreNamed:@"UserWithEvents.sqlite"];
}

- (void)tearDown {
}

/*
 * To make this test run,
 * `cp wammer-iOS.app/UserWithEvents.sqlite Library/Application\ Support/wammer-iOS`
 * TODO: Needs to change the way fixature works.
 */
- (void)disabledForJekinsPhotoStreamViewController {
  WAPhotoStreamViewController *photoStream = [[WAPhotoStreamViewController alloc] initWithDate:[[NSDate alloc]initWithTimeIntervalSince1970:NSTimeIntervalSince1970 +  366018890.0f]];
  // Update library using larry3@wf.com/111111 when tests fails
  STAssertEquals([photoStream.photos count], (NSUInteger)158, @"158 photos");
  
  [photoStream viewDidLoad];
  
  NSInteger max = 3;
  NSMutableArray *lastLayout = [@[@0]mutableCopy];
  NSMutableArray *currentLayout = [@[@(max)]mutableCopy];
  for (NSNumber *aLayout in photoStream.layout) {
    //reset
    if ([[currentLayout valueForKeyPath:@"@sum.intValue"] integerValue] == max){
      STAssertFalse( [lastLayout isEqual:currentLayout], @"Layout should not repeat" );
      lastLayout = currentLayout;
      currentLayout = [NSMutableArray arrayWithCapacity:max];
    }
    
    [currentLayout addObject:aLayout];
  }
}

@end
