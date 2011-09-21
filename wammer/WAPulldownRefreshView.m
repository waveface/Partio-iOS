//
//  WAPulldownRefreshView.m
//  wammer
//
//  Created by Evadne Wu on 9/21/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAPulldownRefreshView.h"

@implementation WAPulldownRefreshView
@synthesize progress, arrowView;

+ (id) viewFromNib {

	return [[[[UINib nibWithNibName:NSStringFromClass(self) bundle:[NSBundle bundleForClass:self]] instantiateWithOwner:nil options:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock: ^ (id evaluatedObject, NSDictionary *bindings) {
		return [evaluatedObject isKindOfClass:self];
	}]] lastObject];

}

- (void) awakeFromNib {

	[super awakeFromNib];

}

- (void) setProgress:(CGFloat)newProgress {

	if (progress == newProgress)
		return;
	
	[self willChangeValueForKey:@"progress"];
	progress = newProgress;
	[self didChangeValueForKey:@"progress"];
	[self setNeedsLayout];

}

- (void) layoutSubviews {

	[super layoutSubviews];
	self.arrowView.layer.transform = CATransform3DMakeRotation(2 * M_PI * ((progress * 180) / 360), 0, 0, 1);

}

@end
