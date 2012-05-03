//
//  WALayoutManagerTestFavoriteMutation.m
//  wammer
//
//  Created by Evadne Wu on 4/24/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WALayoutManagerTestFavoriteMutation.h"
#import "IRDiscreteLayout.h"
#import "WADataStore.h"
#import "WAArticle+DiscreteLayoutAdditions.h"
#import "WADiscreteLayoutHelpers.h"


NSString * const kGrid_6_any_portrait = @"6_any_portrait";
NSString * const kGrid_5_non_faves_A_portrait = @"5_non_faves_A_portrait";
NSString * const kGrid_5_non_faves_B_portrait = @"5_non_faves_B_portrait";
NSString * const kGrid_4_non_faves_A_portrait = @"4_non_faves_A_portrait";
NSString * const kGrid_4_non_faves_B_portrait = @"4_non_faves_B_portrait";
NSString * const kGrid_1_fave_with_4_non_faves_portrait = @"1_fave_with_4_non_faves_portrait";
NSString * const kGrid_1_fave_with_3_non_faves_A_portrait = @"1_fave_with_3_non_faves_A_portrait";
NSString * const kGrid_1_fave_with_3_non_faves_B_portrait = @"1_fave_with_3_non_faves_B_portrait";
NSString * const kGrid_2_faves_portrait = @"2_faves_portrait";



@interface WAArticle (FaveTestingOverride)

- (void) makeCombo;

@end

@implementation WAArticle (FaveTestingOverride)

- (void) makeCombo {

	[self addFilesObject:[WAFile objectInsertingIntoContext:self.managedObjectContext withRemoteDictionary:nil]];

	BOOL isCombo = ((WADiscreteLayoutItemHasLink(self) && WADiscreteLayoutItemHasLongText(self)) || WADiscreteLayoutItemHasImage(self));
	NSParameterAssert(isCombo);
	
}

- (NSString *) description {

	return [NSString stringWithFormat:@"%@ { Fave = %@ }", [self objectID], self.favorite];

}

@end


@interface NSArray (FaveTestingAdditions)

- (id) randomObject;

@end

@implementation NSArray (FaveTestingAdditions)

- (id) randomObject {

	if (![self count])
		return nil;
	
	return [self objectAtIndex:arc4random_uniform([self count])];

}

@end


@interface NSSet (FaveTestingAdditions)

- (id) randomObject;

@end

@implementation NSSet (FaveTestingAdditions)

- (id) randomObject {

	return [[self allObjects] randomObject];

}

@end


@interface WALayoutManagerTestFavoriteMutation ()

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;

- (WAArticle *) newArticle;
- (WAArticle *) newFaveArticle;

- (IRDiscreteLayoutResult *) resultWithGridsAndItems:(id)firstObj, ... NS_REQUIRES_NIL_TERMINATION;
	//	grid, item, item, item, grid, item, ...
	
- (NSArray *) arrayWithNumberOfArticles:(NSUInteger)number;

@end

@implementation WALayoutManagerTestFavoriteMutation
@synthesize managedObjectContext;

- (NSUInteger) numberOfTestIterationsForTestWithSelector:(SEL)testMethod {

	return 100;

}

- (NSManagedObjectContext *) managedObjectContext {

	if (!managedObjectContext) {
	
		managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	
	}
	
	return managedObjectContext;

}

- (IRDiscreteLayoutResult *) resultWithGridsAndItems:(id)firstObj, ... {

	NSMutableArray *instances = [NSMutableArray array];
	
	IRDiscreteLayoutGrid *currentGrid = nil;
	NSMutableArray *currentItems = [NSMutableArray array];
	
	void (^squash)(void) = ^ {
		
		if ([currentItems count])
			[instances addObject:[currentGrid instanceWithItems:currentItems error:nil]];
		
		[currentItems removeAllObjects];
		
	};
	
	va_list args;
	va_start(args, firstObj);
	for (id obj = firstObj; obj != nil; obj = va_arg(args, id)) {
		
		if ([obj isKindOfClass:[IRDiscreteLayoutGrid class]]) {
		
			squash();
			currentGrid = obj;
		
		} else if ([obj conformsToProtocol:@protocol(IRDiscreteLayoutItem)]) {
		
			[currentItems addObject:obj];
		
		}
		
	}
	
	va_end(args);
	squash();
	
	IRDiscreteLayoutResult *result = [IRDiscreteLayoutResult resultWithGrids:instances];
	
	return result;

}

- (NSArray *) arrayWithNumberOfArticles:(NSUInteger)number {

	NSMutableArray *array = [NSMutableArray arrayWithCapacity:number];
	for (NSUInteger i = 0; i < number; i++)
		[array addObject:[self newArticle]];
	
	return array;

}

- (WAArticle *) newArticle {

	return [WAArticle objectInsertingIntoContext:self.managedObjectContext withRemoteDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
	
		@"0", @"favorite",
	
	nil]];

}

- (WAArticle *) newFaveArticle {

	return [WAArticle objectInsertingIntoContext:self.managedObjectContext withRemoteDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
	
		@"1", @"favorite",
	
	nil]];

}

- (IRDiscreteLayoutGrid *) layoutManager:(IRDiscreteLayoutManager *)manager targetGridForEnqueueingProposedGrid:(IRDiscreteLayoutGrid *)proposedGrid fromCandidates:(NSArray *)candidatesSortedByScore toResult:(IRDiscreteLayoutResult *)result {
	
	//	NSLog(@"%s %@ %@ %@ %@", __PRETTY_FUNCTION__, manager, proposedGrid, candidatesSortedByScore, result);
	
	return proposedGrid;

}

- (void) testMutationConstraintsFromFavingInGrid_6_any_portrait {

	self.layoutItems = [self arrayWithNumberOfArticles:6];
	
	IRDiscreteLayoutGrid *fromInstance = [[self layoutGridNamed:kGrid_6_any_portrait] instanceWithItems:self.layoutItems error:nil];
	IRDiscreteLayoutResult *fromResult = [IRDiscreteLayoutResult resultWithGrids:[NSArray arrayWithObject:fromInstance]];
	
	WAArticle *changedItem = ((WAArticle *)[self.layoutItems randomObject]);
	changedItem.favorite = (id)kCFBooleanTrue;
	
	IRDiscreteLayoutResult *toResult = [self.layoutManager calculatedResultWithReference:fromResult strategy:IRCompareScoreLayoutStrategy error:nil];
	
	IRDiscreteLayoutGrid *toInstance = (IRDiscreteLayoutGrid *)[toResult.grids objectAtIndex:0];
	STAssertEqualObjects(toInstance, [toResult gridContainingItem:changedItem], nil);
	STAssertTrue([toInstance.identifier isEqual:kGrid_1_fave_with_4_non_faves_portrait], toInstance.identifier, nil);
	
}

- (void) testMutationConstraintsFromFavingInGrid_5_non_faves_A_portrait {

	self.layoutItems = [self arrayWithNumberOfArticles:5];
	
	[(WAArticle *)[self.layoutItems randomObject] makeCombo];
	
	NSError *error = nil;
	IRDiscreteLayoutGrid *fromPrototype = [self layoutGridNamed:kGrid_5_non_faves_A_portrait];
	IRDiscreteLayoutGrid *fromInstance = [fromPrototype instanceWithItems:self.layoutItems error:&error];
	IRDiscreteLayoutResult *fromResult = [IRDiscreteLayoutResult resultWithGrids:[NSArray arrayWithObject:fromInstance]];
	
	WAArticle *changedItem = ((WAArticle *)[self.layoutItems randomObject]);
	changedItem.favorite = (id)kCFBooleanTrue;
	
	IRDiscreteLayoutResult *toResult = [self.layoutManager calculatedResultWithReference:fromResult strategy:IRCompareScoreLayoutStrategy error:nil];
	NSString *toInstanceID = ((IRDiscreteLayoutGrid *)[toResult.grids objectAtIndex:0]).identifier;
	
	STAssertTrue([toInstanceID isEqual:kGrid_1_fave_with_4_non_faves_portrait] || [toInstanceID isEqual:kGrid_1_fave_with_3_non_faves_A_portrait], toInstanceID);

}

- (void) testMutationConstraintsFromFavingInGrid_5_non_faves_B_portrait {

}

- (void) testMutationConstraintsFromFavingInGrid_4_non_faves_A_portrait {

}

- (void) testMutationConstraintsFromFavingInGrid_4_non_faves_B_portrait {

}

- (void) testMutationConstraintsFromFavingInGrid_1_fave_with_4_non_faves_portrait {

}

- (void) testMutationConstraintsFromFavingInGrid_1_fave_with_3_non_faves_A_portrait {

}

- (void) testMutationConstraintsFromFavingInGrid_1_fave_with_3_non_faves_B_portrait {

}

@end
