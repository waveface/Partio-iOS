//
//  WADiscreteLayoutGrid.m
//  wammer
//
//  Created by Evadne Wu on 5/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADiscreteLayoutGrid.h"

@implementation WADiscreteLayoutGrid
@synthesize eligibilityBlock;

- (BOOL) canInstantiateGrid:(IRDiscreteLayoutGrid *)instance withItems:(NSArray *)providedItems error:(NSError **)outError {

	BOOL superAnswer = [super canInstantiateGrid:instance withItems:providedItems error:outError];
	
	if (self.eligibilityBlock) {
	
		BOOL ownAnswer = self.eligibilityBlock(self, superAnswer);
		
		return ownAnswer;
	
	};
	
	return superAnswer;

}

@end
