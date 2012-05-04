//
//  WADiscreteLayoutGrid.h
//  wammer
//
//  Created by Evadne Wu on 5/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "IRDiscreteLayoutGrid.h"

#ifndef __WADiscreteLayoutGrid__
#define __WADiscreteLayoutGrid__

typedef BOOL (^WALayoutGridEligibilityBlock)(IRDiscreteLayoutGrid *self, BOOL superAnswer);

#endif /* __WADiscreteLayoutGrid__ */

@interface WADiscreteLayoutGrid : IRDiscreteLayoutGrid

@property (nonatomic, readwrite, copy) WALayoutGridEligibilityBlock eligibilityBlock;

@end
