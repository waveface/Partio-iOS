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

@interface WADayViewController (UnitTesting)

@property (nonatomic, readwrite, strong) IRPaginatedView *paginatedView;
@property (nonatomic, readwrite, strong) NSMutableDictionary *daysControllers;
@property (nonatomic, readwrite, strong) NSMutableArray *days;

@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation WADayViewTests {
  WADayViewController *dayViewController;
}

- (void)setUp {
  dayViewController = [[WADayViewController alloc] init];
}

- (void)tearDown {
  dayViewController = nil;
}

- (void)testDayViewWithEventView {
  assertThat(dayViewController, equalTo(dayViewController));
}

@end
