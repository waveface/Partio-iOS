//
//  WAImageStreamPickerView.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/22/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAImageStreamPickerView.h"
#import "WAImageView.h"

static int kWAImageStreamPickerComponent = 24;
static NSString * kWAImageStreamPickerComponentItem = @"WAImageStreamPickerComponentItem";
static NSString * kWAImageStreamPickerComponentIndex = @"WAImageStreamPickerComponentIndex";
static NSString * kWAImageStreamPickerComponentThumbnail = @"WAImageStreamPickerComponentThumbnail";

@interface WAImageStreamPickerView ()
@property (nonatomic, readwrite, retain) NSArray *items;
@property (nonatomic, readwrite, retain) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, readwrite, retain) UIPanGestureRecognizer *panRecognizer;

- (id) itemAtPoint:(CGPoint)aPoint;
@end

@implementation WAImageStreamPickerView
@synthesize items, edgeInsets, activeImageOverlay, delegate;
@synthesize viewForThumbnail;
@synthesize tapRecognizer, panRecognizer, selectedItemIndex;
@synthesize style, thumbnailSpacing, thumbnailAspectRatio;

- (id) init {

	self = [super initWithFrame:(CGRect){ CGPointZero, (CGSize){ 512, 44 } }];
	if (!self)
		return nil;
	
	self.edgeInsets = (UIEdgeInsets){ 12, 8, 12, 8 };
	
	self.viewForThumbnail = ^ (UIView *aView, UIImage *anImage) {
	
		UIImageView *returnedView = nil;
		if ([aView isKindOfClass:[UIImageView class]]) {
			returnedView = (UIImageView *)aView;
			returnedView.image = anImage;
		} else {			
			returnedView = [[[UIImageView alloc] initWithImage:anImage] autorelease];
			returnedView.contentMode = UIViewContentModeScaleAspectFill;
			returnedView.clipsToBounds = YES;
		}
		
		returnedView.layer.borderColor = [UIColor whiteColor].CGColor;
		returnedView.layer.borderWidth = 1.0f;
		
		return returnedView;
	
	};
	
	self.tapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)] autorelease];
	[self addGestureRecognizer:self.tapRecognizer];
	
	self.panRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)] autorelease];
	[self addGestureRecognizer:self.panRecognizer];
	
	self.selectedItemIndex = NSNotFound;
	
	self.thumbnailSpacing = 4.0f;
	self.thumbnailAspectRatio = 2.0f/3.0f;
	
	return self;

}

- (void) setActiveImageOverlay:(UIView *)newActiveImageOverlay {

	if (activeImageOverlay == newActiveImageOverlay)
		return;
	
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
	
	self.selectedItemIndex = [self.items count] ? 0 : NSNotFound;
	
	[self setNeedsLayout];

}

- (void) setStyle:(WAImageStreamPickerViewStyle)newStyle {

	if (style == newStyle)
		return;
	
	style = newStyle;
	[self setNeedsLayout];

}

- (void) setThumbnailSpacing:(CGFloat)newThumbnailSpacing {

	if (thumbnailSpacing == newThumbnailSpacing)
		return;
	
	thumbnailSpacing = newThumbnailSpacing;
	[self setNeedsLayout];

}

- (void) setThumbnailAspectRatio:(CGFloat)newTumbnailAspectRatio {

	NSParameterAssert(newTumbnailAspectRatio > 0);
	if (thumbnailAspectRatio == newTumbnailAspectRatio)
		return;
	
	thumbnailAspectRatio = newTumbnailAspectRatio;
	[self setNeedsLayout];

}

- (void) layoutSubviews {

	[super layoutSubviews];
	
	CGRect usableRect = UIEdgeInsetsInsetRect(self.bounds, self.edgeInsets);
	CGFloat usableWidth = CGRectGetWidth(usableRect);
	CGFloat usableHeight = CGRectGetHeight(usableRect);
	NSUInteger numberOfItems = [self.delegate numberOfItemsInImageStreamPickerView:self];
	NSMutableIndexSet *thumbnailedItemIndices = [NSMutableIndexSet indexSet];
	switch (self.style) {
		case WADynamicThumbnailsStyle: {
			[thumbnailedItemIndices addIndexesInRange:(NSRange){ 0, numberOfItems }];
			break;
		}
		case WAClippedThumbnailsStyle: {
			NSParameterAssert(self.thumbnailAspectRatio);
			NSUInteger numberOfThumbnails = (usableWidth + thumbnailSpacing) / ((usableHeight / self.thumbnailAspectRatio) + thumbnailSpacing);
			float_t delta = (float_t)numberOfItems / (float_t)numberOfThumbnails;
			for (float_t i = delta - 1; i < (numberOfItems - 1); i = i + delta)
				[thumbnailedItemIndices addIndex:roundf(i)];
			break;
		}
	}
	
	NSMutableArray *currentImageThumbnailViews = [[[NSArray irArrayByRepeatingObject:[NSNull null] count:[self.items count]] mutableCopy] autorelease];
	NSMutableSet *removedThumbnailViews = [NSMutableSet set];
	
	id (^itemForComponent)(id) = ^ (id aComponent) {
		return objc_getAssociatedObject(aComponent, &kWAImageStreamPickerComponentItem);
	};
	
	void (^setItemForCompoment)(id, id) = ^ (id aComponent, id anItem) {
		objc_setAssociatedObject(aComponent, &kWAImageStreamPickerComponentItem, anItem, OBJC_ASSOCIATION_ASSIGN);
	};
	
	NSUInteger (^indexForComponent)(id) = ^ (id aComponent) {
		return (NSUInteger)objc_getAssociatedObject(aComponent, &kWAImageStreamPickerComponentIndex);
	};
	
	void (^setIndexForComponent)(id, NSUInteger) = ^ (id aComponent, NSUInteger anIndex) {
		objc_setAssociatedObject(aComponent, &kWAImageStreamPickerComponentIndex, (id)anIndex, OBJC_ASSOCIATION_ASSIGN);
	};
	
	UIImage * (^thumbnailForComponent)(id) = ^ (id aComponent) {
		return objc_getAssociatedObject(aComponent, &kWAImageStreamPickerComponentThumbnail);
	};
	
	void (^setThumbnailForCompoment)(id, id) = ^ (id aComponent, UIImage *aThumbnail) {
		objc_setAssociatedObject(aComponent, &kWAImageStreamPickerComponentThumbnail, aThumbnail, OBJC_ASSOCIATION_RETAIN);
	};
	
	[[[self.subviews copy] autorelease] enumerateObjectsUsingBlock: ^ (UIView *aSubview, NSUInteger idx, BOOL *stop) {
		
		if (aSubview.tag != kWAImageStreamPickerComponent)
			return;
		
		[currentImageThumbnailViews replaceObjectAtIndex:indexForComponent(aSubview) withObject:aSubview];
		[removedThumbnailViews addObject:aSubview];
		
	}];
	
	[thumbnailedItemIndices enumerateIndexesUsingBlock: ^ (NSUInteger idx, BOOL *stop) {
	
		id item = [self.items objectAtIndex:idx];
		
		UIView *thumbnailView = (idx < [currentImageThumbnailViews count] - 1) ? [currentImageThumbnailViews objectAtIndex:idx] : nil;
		UIImage *thumbnailImage = [self.delegate thumbnailForItem:item inImageStreamPickerView:self];
		
		if ([thumbnailView isKindOfClass:[UIView class]]) {
			thumbnailView = self.viewForThumbnail(thumbnailView, thumbnailImage);
		} else {
			thumbnailView = self.viewForThumbnail(nil, thumbnailImage);
			[currentImageThumbnailViews replaceObjectAtIndex:idx withObject:thumbnailView];
		}
			
		thumbnailView.tag = kWAImageStreamPickerComponent;
		setItemForCompoment(thumbnailView, item);
		setIndexForComponent(thumbnailView, idx);
		setThumbnailForCompoment(thumbnailView, thumbnailImage);
		
	}];
	
	__block CGFloat exhaustedWidth = 0;
	
	CGSize (^sizeForComponent)(id) = ^ (id aComponent) {

		CGSize calculatedSize;

		switch (self.style) {
			case WADynamicThumbnailsStyle: {
				calculatedSize = thumbnailForComponent(aComponent).size;
				calculatedSize.width *= 16;
				calculatedSize.height *= 16;
				break;
			}
			case WAClippedThumbnailsStyle: {
				calculatedSize = (CGSize){
					usableHeight / self.thumbnailAspectRatio,
					usableHeight
				};
				break;
			}
		}
		
		CGRect thumbnailRect = CGRectIntegral(IRCGSizeGetCenteredInRect(calculatedSize, usableRect, 0.0f, YES));
		return thumbnailRect.size;
	
	};
	
	[thumbnailedItemIndices enumerateIndexesUsingBlock: ^ (NSUInteger idx, BOOL *stop) {
	
		UIView *thumbnailView = [currentImageThumbnailViews objectAtIndex:idx];
		NSParameterAssert(thumbnailView);
		
		CGSize thumbnailSize = sizeForComponent(thumbnailView);
		CGRect thumbnailRect = (CGRect){
			(CGPoint) {
				0,
				usableRect.origin.y + 0.5f * (CGRectGetHeight(usableRect) - thumbnailSize.height)
			},
			thumbnailSize
		};
		
		exhaustedWidth += CGRectGetWidth(thumbnailRect);
		
		thumbnailView.frame = thumbnailRect;
		[removedThumbnailViews removeObject:thumbnailView];
		
	}];
	
	__block CGFloat leftPadding = 0.5f * (usableWidth - exhaustedWidth);
	
	[thumbnailedItemIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
	
		UIView *thumbnailView = [currentImageThumbnailViews objectAtIndex:idx];
		NSParameterAssert(![removedThumbnailViews containsObject:thumbnailView]);
		
		thumbnailView.frame = CGRectOffset(thumbnailView.frame, leftPadding, 0);
		leftPadding += CGRectGetWidth(thumbnailView.frame);
		
		[self addSubview:thumbnailView];
		
	}];
	
	[removedThumbnailViews enumerateObjectsUsingBlock: ^ (UIView *removedThumbnailView, BOOL *stop) {
		
		[removedThumbnailView removeFromSuperview];
		
	}];
	
	
	if (self.selectedItemIndex != NSNotFound) {
	
		id item = [self.items objectAtIndex:self.selectedItemIndex];
		UIImage *thumbnailImage = [self.delegate thumbnailForItem:item inImageStreamPickerView:self];
	
		if (self.activeImageOverlay)
			self.activeImageOverlay = self.viewForThumbnail(self.activeImageOverlay, thumbnailImage);
		else
			self.activeImageOverlay = self.viewForThumbnail(nil, thumbnailImage);
		
		self.activeImageOverlay.frame = (CGRect){
			CGPointZero,
			sizeForComponent(self.activeImageOverlay)
		};
		
		self.activeImageOverlay.center = (CGPoint){
			0.5 * (usableHeight / self.thumbnailAspectRatio) + 0.5f * (usableWidth - exhaustedWidth) + (((exhaustedWidth - 0.5 * usableHeight) / numberOfItems) * self.selectedItemIndex),
			CGRectGetMidY(usableRect)
		};
		
		self.activeImageOverlay.frame = CGRectInset(self.activeImageOverlay.frame, -4, -4);
				
		if (self != self.activeImageOverlay.superview)
			[self addSubview:self.activeImageOverlay];
		
		[self.activeImageOverlay.superview bringSubviewToFront:self.activeImageOverlay];
	
	} else {
	
		[self.activeImageOverlay removeFromSuperview];
	
	}
			
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
		
	CGPoint hitPoint = [aPanRecognizer locationInView:self];
	hitPoint.y = CGRectGetMidY(self.bounds);

	id hitItem = [self itemAtPoint:hitPoint];
	
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

	CGRect shownFrame = CGRectNull;

	for (UIView *aView in self.subviews) {
		if (aView.tag == kWAImageStreamPickerComponent) {
			if (CGRectEqualToRect(CGRectNull, shownFrame)) {
				shownFrame = aView.frame;
			} else {
				shownFrame = CGRectUnion(shownFrame, aView.frame);
			}
		}
	}
	
	NSUInteger numberOfItems = [self.items count];
	if (!numberOfItems)
		return nil;

	float_t hitIndex = roundf(((aPoint.x - CGRectGetMinX(shownFrame)) / CGRectGetWidth(shownFrame)) * (numberOfItems - 1));
	hitIndex = MIN(numberOfItems - 1, MAX(0, hitIndex));
	
	NSLog(@"%f / %i", hitIndex, numberOfItems);
	
	if (numberOfItems > hitIndex)
		return [self.items objectAtIndex:hitIndex];
	
	return nil;

}

- (void) dealloc {

	[items release];
	[activeImageOverlay release];
	
	[viewForThumbnail release];

	[super dealloc];

}

@end
