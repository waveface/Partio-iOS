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

@interface WAPhotoStreamViewController (UnitTesting)

@property (strong, nonatomic) NSArray *photos;
@property (strong, nonatomic) NSMutableArray *layout;

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
	STAssertTrue([photoDayViewController.days count] >= 0, @"Must be gpreater then 0");

	assertThat([[photoDayViewController controllerAtPageIndex:0] class], equalTo([WAPhotoStreamViewController class]));
	WAPhotoStreamViewController *controller = [photoDayViewController controllerAtPageIndex:0];
	for (int i=0; i<[photoDayViewController numberOfViewsInPaginatedView:nil]; i++) {
		controller = [photoDayViewController controllerAtPageIndex:i];
		NSLog(@"%@, %d", photoDayViewController.days[i], [controller.photos count]);
	}
}

- (void)testPhotoStreamViewController {
	WAPhotoStreamViewController *photoStream = [[WAPhotoStreamViewController alloc] initWithDate:[[NSDate alloc]initWithTimeIntervalSince1970:NSTimeIntervalSince1970 +  366018890.0f]];
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
