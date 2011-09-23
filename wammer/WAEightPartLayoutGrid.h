//
//  WAEightPartLayoutGrid.h
//  wammer
//
//  Created by Evadne Wu on 9/22/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "IRDiscreteLayoutGrid.h"
#import "IRDiscreteLayoutGrid+Transforming.h"
#import "IRDiscreteLayoutItem.h"


@interface WAEightPartLayoutGrid : IRDiscreteLayoutGrid <IRDiscreteLayoutGridEngineUsing>

@property (nonatomic, readwrite, copy) IRDiscreteLayoutGridAreaValidatorBlock validatorBlock;
@property (nonatomic, readwrite, copy) IRDiscreteLayoutGridAreaDisplayBlock displayBlock;

@end
