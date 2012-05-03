//
//  WALayoutManagerTestGeneric.m
//  wammer
//
//  Created by Evadne Wu on 4/24/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WALayoutManagerTestGeneric.h"

@implementation WALayoutManagerTestGeneric

- (void) testGridGeneration {

	IRDiscreteLayoutResult *result = [self.layoutManager calculatedResult];
	
	STAssertNotNil(result, @"Layout should generate result.");

}

- (void) testItemExhaustion {

	IRDiscreteLayoutResult *result = [self.layoutManager calculatedResult];
	
	NSMutableSet *resultItems = [NSMutableSet set];
	
	[result.grids enumerateObjectsUsingBlock: ^ (IRDiscreteLayoutGrid *grid, NSUInteger idx, BOOL *stop) {
	
		for (IRDiscreteLayoutArea *area in grid.layoutAreas)
			if (area.item)
				[resultItems addObject:area.item];
			
	}];
	
	STAssertTrue([[NSSet setWithArray:self.layoutItems] isEqualToSet:resultItems], @"Layout result should exhaust all items, and not introduce unknown items.");

}

@end
