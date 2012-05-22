//
//  WATimelineViewControllerPhone+RowHeightCaching.m
//  wammer
//
//  Created by Evadne Wu on 5/17/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <objc/runtime.h>
#import "WATimelineViewControllerPhone+RowHeightCaching.h"

NSString * const kNonretainedObjectValue = @"-[NSObject(WATimelineViewControllerPhone_RowHeightCaching) watvcpNonretainedObjectValue]";
NSString * const kCache = @"-[WATimelineViewControllerPhone(RowHeightCaching) cache]";


@interface NSObject (WATimelineViewControllerPhone_RowHeightCaching)

- (NSValue *) watvcpNonretainedObjectValue;

@end


@implementation NSObject (WATimelineViewControllerPhone_RowHeightCaching)

- (NSValue *) watvcpNonretainedObjectValue {

	NSValue *value = objc_getAssociatedObject(self, &kNonretainedObjectValue);
	if (!value) {
		value = [NSValue valueWithNonretainedObject:self];
		objc_setAssociatedObject(self, &kNonretainedObjectValue, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	return value;

}

@end


@implementation WATimelineViewControllerPhone (RowHeightCaching)

- (NSCache *) rowHeightCache {

	NSCache *cache = objc_getAssociatedObject(self, &kCache);
	if (!cache) {
	
		cache = [[NSCache alloc] init];
		objc_setAssociatedObject(self, &kCache, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	}
	
	return cache;

}

- (void) cacheRowHeight:(CGFloat)height forObject:(id)object {

	id key = [object watvcpNonretainedObjectValue];

	[[self rowHeightCache] setObject:[NSNumber numberWithFloat:height] forKey:key];

}

- (CGFloat) cachedRowHeightForObject:(id)object {

	id key = [object watvcpNonretainedObjectValue];
	
	return [[[self rowHeightCache] objectForKey:key] floatValue];

}

- (void) removeCachedRowHeightForObject:(id)object {

	id key = [object watvcpNonretainedObjectValue];
	
	[[self rowHeightCache] removeObjectForKey:key];

}

- (void) removeCachedRowHeights {

	[[self rowHeightCache] removeAllObjects];

}

@end
