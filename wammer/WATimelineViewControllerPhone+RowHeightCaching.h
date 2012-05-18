//
//  WATimelineViewControllerPhone+RowHeightCaching.h
//  wammer
//
//  Created by Evadne Wu on 5/17/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WATimelineViewControllerPhone.h"

@interface WATimelineViewControllerPhone (RowHeightCaching)

- (void) cacheRowHeight:(CGFloat)height forObject:(id)object;
- (CGFloat) cachedRowHeightForObject:(id)object;

- (void) removeCachedRowHeightForObject:(id)object;
- (void) removeCachedRowHeights;

- (NSCache *) rowHeightCache;

@end
