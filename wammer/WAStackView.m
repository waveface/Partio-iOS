//
//  WAStackView.m
//  
//
//  Created by Evadne Wu on 12/21/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAStackView.h"


@interface WAStackView ()

- (void) waInit;

@property (nonatomic, readonly, retain) NSArray *stackElements;
- (NSMutableArray *) mutableStackElements; 

@end


@implementation WAStackView
@synthesize stackElements;
@dynamic delegate;

- (id) initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];
	if (!self)
		return nil;
	
	[self waInit];
	
	return self;

}

- (void) awakeFromNib {

	[super awakeFromNib];
	
	[self waInit];

}

- (void) waInit {

	stackElements = [[NSArray array] retain];	
	
	self.bounces = YES;
	self.alwaysBounceHorizontal = NO;
	self.alwaysBounceVertical = NO;

}

- (void) setStackElements:(NSArray *)newStackElements {

	if (stackElements == newStackElements)
		return;
		
	[stackElements release];
	stackElements = [newStackElements retain];
	
	[self setNeedsLayout];

}

- (NSMutableArray *) mutableStackElements {

	return [self mutableArrayValueForKey:@"stackElements"];

}

- (void) addStackElements:(NSSet *)objects {

	[[self mutableStackElements] addObjectsFromArray:[objects allObjects]];
	[self setNeedsLayout];

}

- (void) addStackElementsObject:(UIView *)object {

	[[self mutableStackElements] addObject:object];
	[self setNeedsLayout];

}

- (void) removeStackElements:(NSSet *)objects {

	[[self mutableStackElements] removeObjectsInArray:[objects allObjects]];
	[self setNeedsLayout];

}

- (void) removeStackElementsAtIndexes:(NSIndexSet *)indexes {

	[[self mutableStackElements] removeObjectsAtIndexes:indexes];
	[self setNeedsLayout];

}

- (void) removeStackElementsObject:(UIView *)object {

	[[self mutableStackElements] removeObject:object];
	[self setNeedsLayout];

}

- (void) layoutSubviews {

	[super layoutSubviews];
	
	__block CGPoint nextOffset = CGPointZero;
	__block CGRect contentRect = CGRectZero;
	
	for (UIView *anElement in self.stackElements) {
	
		CGSize fitSize = [self sizeThatFitsElement:anElement];
		CGRect fitFrame = (CGRect){
			nextOffset,
			fitSize
		};
	
		//	if (!CGRectEqualToRect(anElement.frame, fitFrame))
		anElement.frame = fitFrame;
		
		if (anElement.superview != self)
			[self addSubview:anElement];
		
		contentRect = CGRectUnion(contentRect, anElement.frame);
		
		nextOffset = (CGPoint){
			0,
			CGRectGetMaxY(contentRect)
		};
		
		[anElement.superview sendSubviewToBack:anElement];
	
	}
	
	NSParameterAssert(CGPointEqualToPoint(CGPointZero, contentRect.origin));
	
	//	Stretching implementation point
	
	if (!CGSizeEqualToSize(self.contentSize, contentRect.size))
		self.contentSize = contentRect.size;

}

- (CGSize) sizeThatFitsElement:(UIView *)anElement {

	NSParameterAssert([self.stackElements containsObject:anElement]);
	NSParameterAssert(self.delegate);
	
	CGSize bestSize = [self.delegate sizeThatFitsElement:anElement inStackView:self];
	return bestSize;

}

@end
