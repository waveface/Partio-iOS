//
//  WALayoutManagerTestBase.h
//  wammer
//
//  Created by Evadne Wu on 3/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@class IRDiscreteLayoutManager, IRDiscreteLayoutGrid;
@protocol IRDiscreteLayoutManagerDelegate, IRDiscreteLayoutManagerDataSource;

@interface WALayoutManagerTestBase : SenTestCase <IRDiscreteLayoutManagerDelegate, IRDiscreteLayoutManagerDataSource>

@property (nonatomic, readonly, strong) IRDiscreteLayoutManager *layoutManager;
@property (nonatomic, readwrite, strong) NSArray *layoutGrids;
@property (nonatomic, readwrite, strong) NSArray *layoutItems;

- (IRDiscreteLayoutGrid *) layoutGridNamed:(NSString *)name;

@end

//	TBD: Refactor methods in this case into separate smaller test cases
