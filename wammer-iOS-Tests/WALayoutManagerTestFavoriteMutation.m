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


@interface WALayoutManagerTestFavoriteMutation ()

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;

- (WAArticle *) newArticle;
- (WAArticle *) newFaveArticle;

- (IRDiscreteLayoutResult *) resultWithGridsAndItems:(id)firstObj, ... NS_REQUIRES_NIL_TERMINATION;
	//	grid, item, item, item, grid, item, ...

@end

@implementation WALayoutManagerTestFavoriteMutation
@synthesize managedObjectContext;

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
			[instances addObject:[currentGrid instantiatedGridWithAvailableItems:currentItems]];
		
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
	NSLog(@"result %@", result);
	
	return result;

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

- (void) testMutationConstraints {

	IRDiscreteLayoutGrid *grid_6_any_portrait = [self layoutGridNamed:@"6_any_portrait"];
	IRDiscreteLayoutGrid *grid_5_non_faves_A_portrait = [self layoutGridNamed:@"5_non_faves_A_portrait"];
	IRDiscreteLayoutGrid *grid_5_non_faves_B_portrait = [self layoutGridNamed:@"5_non_faves_B_portrait"];
	IRDiscreteLayoutGrid *grid_1_fave_with_4_non_faves_portrait = [self layoutGridNamed:@"1_fave_with_4_non_faves_portrait"];
	IRDiscreteLayoutGrid *grid_2_faves_portrait = [self layoutGridNamed:@"2_faves_portrait"];
	
	[self resultWithGridsAndItems:@"a", @"b", @"c", @"d", nil];

}

@end
