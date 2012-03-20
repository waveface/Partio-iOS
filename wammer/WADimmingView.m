//
//  WADimmingView.m
//  wammer
//
//  Created by Evadne Wu on 12/28/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADimmingView.h"


@interface WADimmingView ()

- (void) waInit;
- (void) handleButtonTap:(UIButton *)sender;

@end

@implementation WADimmingView
@synthesize onAction;

- (id) initWithFrame:(CGRect)aFrame {

	self = [super initWithFrame:aFrame];
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

	UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
	actionButton.frame = self.bounds;
	actionButton.layer.borderColor  = [UIColor redColor].CGColor;
	actionButton.layer.borderWidth = 2;
	actionButton.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[actionButton addTarget:self action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:actionButton];

}

- (void) handleButtonTap:(UIButton *)sender {

	if (self.onAction)
		self.onAction();

}

@end
