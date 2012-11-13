//
//  WADayViewTests.m
//  wammer
//
//  Created by jamie on 11/10/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADayViewTests.h"
#import "WADayViewController.h"
#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "WADataStore.h"

#import "WAPhotoStreamViewController.h"
#import "WATimelineViewControllerPhone.h"

@interface WADayViewController (UnitTesting)

- (id) controllerAtPageIndex: (NSUInteger) index;

@end

@implementation WADayViewTests {
  WADayViewController *eventDayViewController;
	WADayViewController *photoDayViewController;
}

- (void)setUp {
	[MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"UserWithTwoEventsAndThreePhotos.sqlite"];
	eventDayViewController = [[WADayViewController alloc] initWithClassNamed:[WATimelineViewControllerPhone class]];
	photoDayViewController = [[WADayViewController alloc] initWithClassNamed:[WAPhotoStreamViewController class]];
}

- (void)tearDown {
  eventDayViewController = nil;
}

- (void)testDayViewWithEventView {
  [eventDayViewController loadView];
	assertThat([[eventDayViewController controllerAtPageIndex:0] class], equalTo([WATimelineViewControllerPhone class]));
}

- (void)testDayViewWithPhotosView {
	[photoDayViewController loadView];
	assertThat([[photoDayViewController controllerAtPageIndex:0] class], equalTo([WAPhotoStreamViewController class]));
	WAPhotoStreamViewController *controller = (WAPhotoStreamViewController *)[photoDayViewController controllerAtPageIndex:0];
	assertThat([controller.delegate class], equalTo([WADayViewController class]));
}

@end
