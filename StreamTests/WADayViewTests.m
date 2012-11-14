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
#import "WATimelineViewControllerPhone.h"

@interface WADayViewController (UnitTesting)

@property (nonatomic, readwrite, strong) NSMutableDictionary *daysControllers;
@property (nonatomic, readwrite, strong) NSMutableArray *days;

- (id) controllerAtPageIndex: (NSUInteger) index;

@end

@implementation WADayViewTests {
  WADayViewController *eventDayViewController;
	WADayViewController *photoDayViewController;
}

- (void)setUp {
	[MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"UserWithEvents.sqlite"];
	eventDayViewController = [[WADayViewController alloc] initWithClassNamed:[WATimelineViewControllerPhone class]];
	photoDayViewController = [[WADayViewController alloc] initWithClassNamed:[WAPhotoStreamViewController class]];
}

- (void)tearDown {
  eventDayViewController = nil;
}

- (void)t1estDayViewWithEventView {
  [eventDayViewController loadView];
	assertThat([[eventDayViewController controllerAtPageIndex:0] class], equalTo([WATimelineViewControllerPhone class]));
}

- (void)testDayViewWithPhotosView {
	[photoDayViewController loadView];
	assertThat([[photoDayViewController controllerAtPageIndex:0] class], equalTo([WAPhotoStreamViewController class]));
	STAssertTrue([photoDayViewController.days count] >= 0, @"Must be greater then 0");
}

@end
