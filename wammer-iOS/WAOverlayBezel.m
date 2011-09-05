//
//  WAOverlayBezel.m
//  wammer-iOS
//
//  Created by Evadne Wu on 9/2/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "WAOverlayBezel.h"


@interface WAOverlayBezel ()

@property (nonatomic, readwrite, assign) WAOverlayBezelStyle *style;

@end


@implementation WAOverlayBezel

@synthesize style;

+ (WAOverlayBezel *) bezelWithStyle:(WAOverlayBezelStyle)aStyle {

	return [[(WAOverlayBezel *)[self alloc] initWithStyle:aStyle] autorelease];

}

- (WAOverlayBezel *) initWithStyle:(WAOverlayBezelStyle)aStyle {

	self = [super initWithFrame:CGRectZero];
	if (!self)
		return nil;
	
	return self;

}

- (id) initWithFrame:(CGRect)aFrame {

	self = [self initWithStyle:WAOverlayBezelDefaultStyle];
	if (!self)
		return nil;
	
	self.frame = aFrame;
	
	return self;

}

- (void) show {

	//	shows me
	
	if (self.window)
		[NSException raise:NSInternalInconsistencyException format:@"%s shall only be called when the current alert view is not on screen.", __PRETTY_FUNCTION__];
	
	//	peg something into the window

}

@end
