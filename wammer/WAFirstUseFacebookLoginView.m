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

	self.facebookLoginButton.backgroundColor = [UIColor blueColor];
	self.facebookLoginButton.layer.cornerRadius = 17.0;
	[self.facebookLoginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[self.facebookLoginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
	self.facebookLoginButton.imageView.layer.cornerRadius = 15.0;

}

@end
