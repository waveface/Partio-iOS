//
//  WALayoutManagerTest.m
//  wammer
//
//  Created by Evadne Wu on 3/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WALayoutManagerTest.h"
#import "IRDiscreteLayoutManager.h"
#import "IRDiscreteLayoutGrid.h"

#import "WADataStore.h"
#import "WAArticle+DiscreteLayoutAdditions.h"
#import "WADiscreteLayoutHelpers.h"


@interface WALayoutManagerTest () <IRDiscreteLayoutManagerDelegate, IRDiscreteLayoutManagerDataSource>

@property (nonatomic, strong) IRDiscreteLayoutManager *layoutManager;
@property (nonatomic, strong) NSArray *layoutGrids;
@property (nonatomic, strong) NSArray *layoutItems;

//	Creation conveniences, not for actual test cases
- (IRDiscreteLayoutManager *) newLayoutManager;
- (NSArray *) newLayoutGrids;
- (NSArray *) newLayoutItems;

@end

@implementation WALayoutManagerTest


- (void) testGridGeneration {

	IRDiscreteLayoutResult *result = [self.layoutManager calculatedResult];
	
	STAssertNotNil(result, @"Layout should generate result.");

}

- (void) testItemExhaustion {

	IRDiscreteLayoutResult *result = [self.layoutManager calculatedResult];
	
	NSMutableSet *resultItems = [NSMutableSet set];
	
	[result.grids enumerateObjectsUsingBlock: ^ (IRDiscreteLayoutGrid *grid, NSUInteger idx, BOOL *stop) {
	
		[grid enumerateLayoutAreasWithBlock:^(NSString *name, id item, IRDiscreteLayoutGridAreaValidatorBlock validatorBlock, IRDiscreteLayoutGridAreaLayoutBlock layoutBlock, IRDiscreteLayoutGridAreaDisplayBlock displayBlock) {
		
			if (item)
				[resultItems addObject:item];
			
		}];
		
	}];
	
	STAssertTrue([[NSSet setWithArray:self.layoutItems] isEqualToSet:resultItems], @"Layout result should exhaust all items, and not introduce unknown items.");

}

- (void) testRelevancyGrouping {

	//	?

}

- (void) testCohesiveness {

	//	?

}

- (void) testResultMutation {

	//	?

}

- (NSUInteger) numberOfItemsForLayoutManager:(IRDiscreteLayoutManager *)manager {

	NSParameterAssert(manager == self.layoutManager);
	
	return [self.layoutItems count];

}

- (id<IRDiscreteLayoutItem>) layoutManager:(IRDiscreteLayoutManager *)manager itemAtIndex:(NSUInteger)index {

	NSParameterAssert(manager == self.layoutManager);
	
	return [self.layoutItems objectAtIndex:index];

}

- (NSInteger) layoutManager:(IRDiscreteLayoutManager *)manager indexOfLayoutItem:(id<IRDiscreteLayoutItem>)item {

	NSParameterAssert(manager == self.layoutManager);
	
	return [self.layoutItems indexOfObject:item];

}

- (NSUInteger) numberOfLayoutGridsForLayoutManager:(IRDiscreteLayoutManager *)manager {

	NSParameterAssert(manager == self.layoutManager);
	
	return [self.layoutGrids count];

}

- (IRDiscreteLayoutGrid *) layoutManager:(IRDiscreteLayoutManager *)manager layoutGridAtIndex:(NSUInteger)index {

	NSParameterAssert(manager == self.layoutManager);
	
	return [self.layoutGrids objectAtIndex:index];

}

- (NSInteger) layoutManager:(IRDiscreteLayoutManager *)manager indexOfLayoutGrid:(IRDiscreteLayoutGrid *)grid {

	NSParameterAssert(manager == self.layoutManager);
	
	return [self.layoutGrids indexOfObject:grid];

}

- (IRDiscreteLayoutManager *) layoutManager {

	if (_layoutManager)
		return _layoutManager;
	
	_layoutManager = [self newLayoutManager];
	_layoutManager.dataSource = self;
	_layoutManager.delegate = self;
	
	return _layoutManager;

}

- (NSArray *) layoutGrids {

	if (_layoutGrids)
		return _layoutGrids;
		
	_layoutGrids = [self newLayoutGrids];
	
	return _layoutGrids;

}

- (NSArray *) layoutItems {

	if (_layoutItems)
		return _layoutItems;
	
	_layoutItems = [self newLayoutItems];

	return _layoutItems;

}

- (void) tearDown {

	self.layoutManager.delegate = nil;
	self.layoutManager = nil;
	self.layoutGrids = nil;
	self.layoutItems = nil;
	
	[super tearDown];

}

- (IRDiscreteLayoutManager *) newLayoutManager {

	return [IRDiscreteLayoutManager new];

}

- (NSArray *) newLayoutGrids {

	static NSArray * grids = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
			
		grids = WADefaultLayoutGrids();

	});

	return grids;

}

- (NSArray *) newLayoutItems {

		NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
	
		static NSUInteger const numberOfItems = 200;
		
		WAArticle * (^newArticle)(void) = ^ {
		
			WAArticle *article = [WAArticle objectInsertingIntoContext:context withRemoteDictionary:nil];
			
			return article;
		
		};
		
		NSMutableArray *answer = [NSMutableArray arrayWithCapacity:numberOfItems];
		
		for (unsigned int i = 0; i < numberOfItems; i++) {
		
			WAArticle *article = newArticle();
			[answer addObject:article];
		
		};
		
		return answer;

}

@end
