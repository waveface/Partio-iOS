//
//  IRDiscreteLayoutArea+WAAdditions.h
//  wammer
//
//  Created by Evadne Wu on 5/2/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "IRDiscreteLayoutArea.h"

#ifndef __WADiscreteLayoutArea__
#define __WADiscreteLayoutArea__

typedef NSString * (^WALayoutAreaTemplateNameBlock)(IRDiscreteLayoutArea *self);

#endif /* __WADiscreteLayoutArea__ */


@interface WADiscreteLayoutArea : IRDiscreteLayoutArea

@property (nonatomic, readwrite, copy) WALayoutAreaTemplateNameBlock templateNameBlock;

@end
