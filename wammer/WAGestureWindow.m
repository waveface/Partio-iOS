//
//  WAGestureWindow.m
//  wammer
//
//  Created by Evadne Wu on 1/11/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAGestureWindow.h"


@interface WAGestureWindow () <UIGestureRecognizerDelegate>

@property (nonatomic, readwrite, retain) UITapGestureRecognizer *tapGestureRecognizer;

- (void) handleTapGesture:(UITapGestureRecognizer *)aTGR;

@end


@implementation WAGestureWindow
@synthesize tapGestureRecognizer, onTap, onGestureRecognizeShouldReceiveTouch, onGestureRecognizeShouldRecognizeSimultaneouslyWithGestureRecognizer;

- (id) initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];
	if (!self)
		return nil;
	
	tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
	tapGestureRecognizer.delegate = self;
	
	[self addGestureRecognizer:tapGestureRecognizer];
	
	return self;

}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {

	if (self.onGestureRecognizeShouldReceiveTouch) {
		BOOL returnValue = self.onGestureRecognizeShouldReceiveTouch(gestureRecognizer, touch);
		return returnValue;
	}
	
	return NO;

}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {

	if (self.onGestureRecognizeShouldRecognizeSimultaneouslyWithGestureRecognizer)
		return self.onGestureRecognizeShouldRecognizeSimultaneouslyWithGestureRecognizer(gestureRecognizer, otherGestureRecognizer);

	return YES;

}

- (void) handleTapGesture:(UITapGestureRecognizer *)aTGR {

	if (onTap)
		onTap();

}

- (void) dealloc {

	[tapGestureRecognizer release];

	[onTap release];
	[onGestureRecognizeShouldReceiveTouch release];
	[onGestureRecognizeShouldRecognizeSimultaneouslyWithGestureRecognizer release];
	
	[super dealloc];

}

//- (id) retain {
//
//	NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSThread callStackSymbols]);
//	return [super retain];
//
//}
//
//- (id) autorelease {
//
//	NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSThread callStackSymbols]);
//	return [super autorelease];
//
//}
//
//- (oneway void) release {
//
//	NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSThread callStackSymbols]);
//	[super release];
//
//}

@end
