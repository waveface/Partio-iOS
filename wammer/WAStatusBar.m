//
//  WAStatusBar.m
//  wammer
//
//  Created by kchiu on 12/11/15.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAStatusBar.h"

@implementation WAStatusBar

- (id)initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];
	if (self) {

		self.windowLevel = UIWindowLevelStatusBar + 1.0;
		self.frame = [UIApplication sharedApplication].statusBarFrame;
		self.backgroundColor = [UIColor blackColor];
		self.hidden = NO;
		
		self.statusLabel = [[UILabel alloc] init];
		self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
		self.statusLabel.textColor = [UIColor whiteColor];
		self.statusLabel.font = [UIFont boldSystemFontOfSize:13.0];
		self.statusLabel.backgroundColor = [UIColor blackColor];
		[self addSubview:self.statusLabel];

		self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
		self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
		self.progressView.progressTintColor = [UIColor whiteColor];
		self.progressView.trackTintColor = [UIColor blackColor];
		self.progressView.layer.borderWidth = 2.0;
		self.progressView.layer.borderColor = [[UIColor whiteColor] CGColor];
		self.progressView.layer.cornerRadius = 5.0;
		[self addSubview:self.progressView];

		UILabel *status = self.statusLabel;
		UIProgressView *progress = self.progressView;
		
		NSDictionary *viewDic = NSDictionaryOfVariableBindings(status, progress);
		[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[status(==20@500)]-[progress(==100)]-5-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:viewDic]];
		[self addConstraint:[NSLayoutConstraint constraintWithItem:self.statusLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
		[self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:-1]];

	}
	return self;

}

@end
