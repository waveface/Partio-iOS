//
//  WALayoutManagerTestBase.h
//  wammer
//
//  Created by Evadne Wu on 3/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@class IRDiscreteLayoutManager, IRDiscreteLayoutGrid;
@interface WALayoutManagerTestBase : SenTestCase

@property (nonatomic, readonly, strong) IRDiscreteLayoutManager *layoutManager;
@property (nonatomic, readonly, strong) NSArray *layoutGrids;
@property (nonatomic, readonly, strong) NSArray *layoutItems;

- (IRDiscreteLayoutGrid *) layoutGridNamed:(NSString *)name;

@end

//	TBD: Refactor methods in this case into separate smaller test cases
