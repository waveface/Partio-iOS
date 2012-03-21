//
//  WADiscreteLayoutHelpers.h
//  wammer
//
//  Created by Evadne Wu on 3/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "IRDiscreteLayoutManager.h"

extern BOOL WADiscreteLayoutItemHasMediaOfType (id<IRDiscreteLayoutItem> anItem, CFStringRef aMediaType);
extern BOOL WADiscreteLayoutItemHasImage (id<IRDiscreteLayoutItem> anItem);
extern BOOL WADiscreteLayoutItemHasLink (id<IRDiscreteLayoutItem> anItem);
extern BOOL WADiscreteLayoutItemHasShortText (id<IRDiscreteLayoutItem> anItem);
extern BOOL WADiscreteLayoutItemHasLongText (id<IRDiscreteLayoutItem> anItem);

extern NSArray * WADefaultLayoutGrids (void);
