//
//  WAImageStreamPickerView.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/22/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAImageStreamPickerView.h"

@implementation WAImageStreamPickerView
@synthesize edgeInsets, activeImageOverlay, delegate;

- (void) setActiveImageOverlay:(UIView *)newActiveImageOverlay {

	[activeImageOverlay removeFromSuperview];
	
	[self willChangeValueForKey:@"activeImageOverlay"];
	[activeImageOverlay release];
	activeImageOverlay = [newActiveImageOverlay retain];
	[self didChangeValueForKey:@"activeImageOverlay"];
	
	[self setNeedsLayout];

}

- (void) layoutSubviews {

	[super layoutSubviews];

}

- (void) dealloc {

	[activeImageOverlay release];

	[super dealloc];

}

@end
