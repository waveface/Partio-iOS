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
@synthesize viewForThumbnail;

- (id) init {

	self = [super initWithFrame:(CGRect){ CGPointZero, (CGSize){ 512, 44 } }];
	if (!self)
		return nil;
	
	self.edgeInsets = (UIEdgeInsets){ 8, 8, 8, 8 };
	
	self.viewForThumbnail = ^ (UIImage *anImage) {
	
		UIImageView *returnedView = [[[UIImageView alloc] initWithImage:anImage] autorelease];
		returnedView.layer.borderColor = [UIColor whiteColor].CGColor;
		returnedView.layer.borderWidth = 1.0f;
		
		return returnedView;
	
	};
	
	return self;

}

- (void) setActiveImageOverlay:(UIView *)newActiveImageOverlay {

	[activeImageOverlay removeFromSuperview];
	
	[self willChangeValueForKey:@"activeImageOverlay"];
	[activeImageOverlay release];
	activeImageOverlay = [newActiveImageOverlay retain];
	[self didChangeValueForKey:@"activeImageOverlay"];
	
	[self setNeedsLayout];

}

- (void) reloadData {

	NSLog(@"%s, delegate %@", __PRETTY_FUNCTION__, self.delegate);

	NSUInteger numberOfItems = [self.delegate numberOfItemsInImageStreamPickerView:self];
	NSMutableArray *allItems = [NSMutableArray arrayWithCapacity:numberOfItems];
	
	for (NSUInteger i = 0; i < numberOfItems; i++)
		[allItems insertObject:[self.delegate itemAtIndex:i inImageStreamPickerView:self] atIndex:i];
	
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
	
	[[[self.subviews copy] autorelease] enumerateObjectsUsingBlock:^(UIView *aSubview, NSUInteger idx, BOOL *stop) {
		
		if (aSubview.tag != kWAImageStreamPickerComponent)
			return;
			
		if (![self.items containsObject:itemForThumbnailView(aSubview)])
			[aSubview removeFromSuperview];
		else
			[imageThumbnailViews replaceObjectAtIndex:idx withObject:aSubview];
		
	}];

	[[[imageThumbnailViews copy] autorelease] enumerateObjectsUsingBlock: ^ (UIView *aSubview, NSUInteger idx, BOOL *stop) {
	
		if (![aSubview isEqual:[NSNull null]])
			return;
		
		UIView *thumbnailView = self.viewForThumbnail([self.delegate thumbnailForItem:[self.items objectAtIndex:idx] inImageStreamPickerView:self]);
				
		if (!thumbnailView)
			return;
		
		thumbnailView.tag = kWAImageStreamPickerComponent;
		[imageThumbnailViews replaceObjectAtIndex:idx withObject:thumbnailView];
		
	}];
	
	CGRect usableRect = UIEdgeInsetsInsetRect(self.bounds, self.edgeInsets);
	__block CGFloat exhaustedWidth = 0;
	
	[imageThumbnailViews enumerateObjectsUsingBlock: ^ (UIView *thumbnailView, NSUInteger idx, BOOL *stop) {
	
		CGRect thumbnailRect = IRCGSizeGetCenteredInRect(thumbnailView.frame.size, usableRect, 0.0f, YES);
		thumbnailRect = CGRectIntegral(thumbnailRect);
		thumbnailRect.origin.x = exhaustedWidth;
		thumbnailView.frame = thumbnailRect;
		
		exhaustedWidth += CGRectGetWidth(thumbnailRect);
		
		[self addSubview:thumbnailView];
		
	}];
			
}

- (void) dealloc {

	[items release];
	[itemThumbnails release];
	[activeImageOverlay release];
	
	[viewForThumbnail release];

	[super dealloc];

}

@end
