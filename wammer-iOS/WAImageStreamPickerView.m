//
//  WAImageStreamPickerView.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/22/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAImageStreamPickerView.h"


@interface WAImageStreamPickerView ()
@property (nonatomic, readwrite, retain) NSArray *items;
@property (nonatomic, readwrite, retain) NSArray *itemThumbnails;
@end

@implementation WAImageStreamPickerView
@synthesize items, itemThumbnails, edgeInsets, activeImageOverlay, delegate;

- (void) setActiveImageOverlay:(UIView *)newActiveImageOverlay {

	[activeImageOverlay removeFromSuperview];
	
	[self willChangeValueForKey:@"activeImageOverlay"];
	[activeImageOverlay release];
	activeImageOverlay = [newActiveImageOverlay retain];
	[self didChangeValueForKey:@"activeImageOverlay"];
	
	[self setNeedsLayout];

}

- (void) reloadData {

	NSMutableArray *allItems = [NSMutableArray arrayWithCapacity:[self.delegate numberOfItemsInImageStreamPickerView:self]];
	
	for (NSUInteger i = 0; i < [self.items count]; i++)
		[allItems insertObject:[self.delegate itemInImageStreamPickerView:self] atIndex:i];
	
	self.items = allItems;
	self.itemThumbnails = [self.items irMap: ^ (id anItem, int index, BOOL *stop) {
		return [self.delegate thumbnailForItem:anItem inImageStreamPickerView:self];
	}];
	
	[self setNeedsLayout];

}

- (void) layoutSubviews {

	[super layoutSubviews];

	static int kWAImageStreamPickerComponent = 24;
	static NSString * kWAImageStreamPickerComponentItem = @"kWAImageStreamPickerComponentItem";
	
	NSMutableArray *imageThumbnailViews = [[[NSArray irArrayByRepeatingObject:[NSNull null] count:[self.items count]] mutableCopy] autorelease];
	
	id (^itemForThumbnailView)(UIView *) = ^ (UIView *aView) {
	
		return objc_getAssociatedObject(aView, kWAImageStreamPickerComponentItem);
	
	};
	
	UIView * (^thumbnailViewForItem)(id) = ^ (id anItem) {
	
		return [[imageThumbnailViews objectsAtIndexes:[imageThumbnailViews indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
			return (BOOL)(itemForThumbnailView(obj) == anItem);
			
		}]] lastObject];
	
	};
	
	//	imageThumbnailViews
	
	for (UIView *aSubview in [[self.subviews copy] autorelease])
		if (aSubview.tag == kWAImageStreamPickerComponent) {
			if (![self.items containsObject:itemForThumbnailView(aSubview)])
				[aSubview removeFromSuperview];
			else
				[imageThumbnailViews replaceObjectAtIndex:index withObject:aSubview];
		}
		
}

- (void) dealloc {

	[items release];
	[itemThumbnails release];
	[activeImageOverlay release];

	[super dealloc];

}

@end
