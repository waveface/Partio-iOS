//
//  WAFirstUseFacebookLoginView.m
//  wammer
//
//  Created by kchiu on 12/11/6.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseFacebookLoginView.h"

@implementation WAFirstUseFacebookLoginView

+ (WAFirstUseFacebookLoginView *)viewFromNib {
	
	WAFirstUseFacebookLoginView *view = [[[UINib nibWithNibName:@"WAFirstUseFacebookLoginView" bundle:[NSBundle mainBundle]] instantiateWithOwner:nil options:nil] lastObject];

	return view;

}

- (void)awakeFromNib {
	
	[super awakeFromNib];

	self.backgroundColor = [UIColor colorWithRed:0xf4/255.0 green:0xf4/255.0 blue:0xf4/255.0 alpha:1.0];

	self.facebookLoginButton.backgroundColor = [UIColor colorWithRed:0x2d/255.0 green:0x47/255.0 blue:0x79/255.0 alpha:1.0];
	self.facebookLoginButton.layer.cornerRadius = 20.0;
	[self.facebookLoginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[self.facebookLoginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
	self.facebookLoginButton.imageView.layer.cornerRadius = 15.0;
	UIImageView *image = self.facebookLoginButton.imageView;
	self.facebookLoginButton.imageView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.facebookLoginButton addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(5)-[image]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(image)]];
	self.facebookLoginButton.contentEdgeInsets = UIEdgeInsetsMake(5.0, 0.0, 5.0, 0.0);

	self.orLabel.textColor = [UIColor whiteColor];
	self.orLabel.backgroundColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.0];
	self.orLabel.layer.cornerRadius = 15.0;

	UIView *line = [[UIView alloc] init];
	line.translatesAutoresizingMaskIntoConstraints = NO;
	line.backgroundColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.0];
	[self insertSubview:line belowSubview:self.orLabel];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[line]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(line)]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[line(==2)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(line)]];
	[self addConstraint:[NSLayoutConstraint constraintWithItem:line attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.orLabel attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];

}

@end
