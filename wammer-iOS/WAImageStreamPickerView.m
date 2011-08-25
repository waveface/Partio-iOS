//
//  WAImageStreamPickerView.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/22/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAImageStreamPickerView.h"


static int kWAImageStreamPickerComponent = 24;
static NSString * kWAImageStreamPickerComponentItem = @"kWAImageStreamPickerComponentItem";

@interface WAImageStreamPickerView ()
@property (nonatomic, readwrite, retain) NSArray *items;
@property (nonatomic, readwrite, retain) NSArray *itemThumbnails;
@property (nonatomic, readwrite, retain) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, readwrite, retain) UIPanGestureRecognizer *panRecognizer;

- (id) itemAtPoint:(CGPoint)aPoint;
@end

@implementation WAImageStreamPickerView
@synthesize items, itemThumbnails, edgeInsets, activeImageOverlay, delegate;
@synthesize viewForThumbnail;
@synthesize tapRecognizer, panRecognizer, selectedItemIndex;

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
	
	self.tapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
	[self addGestureRecognizer:self.tapRecognizer];
	
	self.panRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)] autorelease];
	[self addGestureRecognizer:self.panRecognizer];
	
	self.selectedItemIndex = NSNotFound;
	
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

- (void) setSelectedItemIndex:(NSUInteger)newSelectedItemIndex {

	if (selectedItemIndex == newSelectedItemIndex)
		return;
	
	[self willChangeValueForKey:@"selectedItemIndex"];
	selectedItemIndex = newSelectedItemIndex;
	[self didChangeValueForKey:@"selectedItemIndex"];
	[self setNeedsLayout];

}

- (void) reloadData {

	NSUInteger numberOfItems = [self.delegate numberOfItemsInImageStreamPickerView:self];
	NSMutableArray *allItems = [NSMutableArray arrayWithCapacity:numberOfItems];
	
	for (NSUInteger i = 0; i < numberOfItems; i++)
		[allItems insertObject:[self.delegate itemAtIndex:i inImageStreamPickerView:self] atIndex:i];
	
	self.items = allItems;
	
	self.itemThumbnails = [self.items irMap: ^ (id anItem, int index, BOOL *stop) {
		return [self.delegate thumbnailForItem:anItem inImageStreamPickerView:self];
	}];
	
	self.selectedItemIndex = [self.items count] ? 0 : NSNotFound;
	
	[self setNeedsLayout];

}

- (void) layoutSubviews {

	[super layoutSubviews];
	
	NSMutableArray *imageThumbnailViews = [[[NSArray irArrayByRepeatingObject:[NSNull null] count:[self.items count]] mutableCopy] autorelease];
	
	id (^itemForThumbnailView)(UIView *) = ^ (UIView *aView) {
	
		return objc_getAssociatedObject(aView, kWAImageStreamPickerComponentItem);
	
	};
	
	
	//	UIView * (^thumbnailViewForItem)(id) = ^ (id anItem) {
	//	
	//		return [[imageThumbnailViews objectsAtIndexes:[imageThumbnailViews indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
	//			return (BOOL)(itemForThumbnailView(obj) == anItem);
	//			
	//		}]] lastObject];
	//	
	//	};
	
	[[[self.subviews copy] autorelease] enumerateObjectsUsingBlock:^(UIView *aSubview, NSUInteger idx, BOOL *stop) {
		
		if (aSubview.tag != kWAImageStreamPickerComponent)
			return;
			
		id item = itemForThumbnailView(aSubview);
			
		if (![self.items containsObject:item])
			[aSubview removeFromSuperview];
		else
			[imageThumbnailViews replaceObjectAtIndex:[self.items indexOfObject:item] withObject:aSubview];
		
	}];

	[[[imageThumbnailViews copy] autorelease] enumerateObjectsUsingBlock: ^ (UIView *aSubview, NSUInteger idx, BOOL *stop) {
	
		if (![aSubview isEqual:[NSNull null]])
			return;
			
		id item = [self.items objectAtIndex:idx];
		
		UIImage *thumbnail = [self.delegate thumbnailForItem:item inImageStreamPickerView:self];
		
		UIView *thumbnailView = self.viewForThumbnail(thumbnail);
		objc_setAssociatedObject(thumbnailView, kWAImageStreamPickerComponentItem, item, OBJC_ASSOCIATION_ASSIGN);
				
		if (!thumbnailView)
			return;
		
		thumbnailView.tag = kWAImageStreamPickerComponent;
		[imageThumbnailViews replaceObjectAtIndex:idx withObject:thumbnailView];
		
	}];
	
	CGRect usableRect = UIEdgeInsetsInsetRect(self.bounds, self.edgeInsets);
	__block CGFloat exhaustedWidth = 0;
	CGFloat usableWidth = CGRectGetWidth(usableRect);
	
	__block UIView *selectedThumbnailView = nil;
	
	[imageThumbnailViews enumerateObjectsUsingBlock: ^ (UIView *thumbnailView, NSUInteger idx, BOOL *stop) {
	
		BOOL currentItemIsSelected = (self.selectedItemIndex == idx);
		
		CGSize calculatedSize = (CGSize){
			16.0f * thumbnailView.frame.size.width,
			16.0f * thumbnailView.frame.size.height
		};
		
		CGRect thumbnailRect = IRCGSizeGetCenteredInRect(calculatedSize, usableRect, 0.0f, YES);
		
		thumbnailRect = CGRectIntegral(thumbnailRect);
		thumbnailRect.origin.x = exhaustedWidth;
		thumbnailView.frame = thumbnailRect;
		exhaustedWidth += CGRectGetWidth(thumbnailRect);
		
		if (currentItemIsSelected) {
			
			selectedThumbnailView = thumbnailView;
			CGRect actualThumbnailRect = IRCGSizeGetCenteredInRect(calculatedSize, usableRect, -4.0f, YES);
			actualThumbnailRect.origin.x = exhaustedWidth - CGRectGetWidth(thumbnailRect) - (CGRectGetWidth(actualThumbnailRect) - CGRectGetWidth(thumbnailRect));
			thumbnailView.frame = actualThumbnailRect;
			
		}
		
		[self addSubview:thumbnailView];		
		
	}];
	
	CGFloat leftPadding = roundf(0.5f * (usableWidth - exhaustedWidth)) + 8;
	if (leftPadding > 0)
		for (UIView *aThumbnailView in imageThumbnailViews) {
			aThumbnailView.frame = CGRectOffset(aThumbnailView.frame, leftPadding, 0);
		}
	
	[selectedThumbnailView.superview bringSubviewToFront:selectedThumbnailView];
		
}

- (void) handleTap:(UITapGestureRecognizer *)aTapRecognizer {

	id hitItem = [self itemAtPoint:[aTapRecognizer locationInView:self]];
	
	if (!hitItem)
		return;
	
	NSUInteger newItemIndex = [self.items indexOfObject:hitItem];
	
	if (self.selectedItemIndex == newItemIndex)
		return;
	
	self.selectedItemIndex = newItemIndex;
	[self.delegate imageStreamPickerView:self didSelectItem:hitItem];
	[self setNeedsLayout];

}

- (void) handlePan:(UIPanGestureRecognizer *)aPanRecognizer {

	if (aPanRecognizer.state != UIGestureRecognizerStateChanged)
		return;

	id hitItem = [self itemAtPoint:[aPanRecognizer locationInView:self]];
	
	if (!hitItem)
		return;

	NSUInteger newItemIndex = [self.items indexOfObject:hitItem];
	
	if (self.selectedItemIndex == newItemIndex)
		return;
	
	self.selectedItemIndex = newItemIndex;
	[self.delegate imageStreamPickerView:self didSelectItem:hitItem];
	[self setNeedsLayout];
	
}

- (id) itemAtPoint:(CGPoint)aPoint {

	for (UIView *aView in self.subviews)
		if (aView.tag == kWAImageStreamPickerComponent)
			if ([aView pointInside:[self convertPoint:aPoint toView:aView] withEvent:nil])
				return objc_getAssociatedObject(aView, kWAImageStreamPickerComponentItem);
	
	return nil;

}

- (void) dealloc {

	[items release];
	[itemThumbnails release];
	[activeImageOverlay release];
	
	[viewForThumbnail release];

	[super dealloc];

}

@end
