//
//  WAFirstUseEmailLoginFooterView.m
//  wammer
//
//  Created by kchiu on 12/11/6.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseEmailLoginFooterView.h"

@implementation WAFirstUseEmailLoginFooterView

+ (WAFirstUseEmailLoginFooterView *)viewFromNib {

	WAFirstUseEmailLoginFooterView *view = [[[UINib nibWithNibName:@"WAFirstUseEmailLoginFooterView" bundle:[NSBundle mainBundle]] instantiateWithOwner:nil options:nil] lastObject];

	return view;

}

- (void)awakeFromNib {

	[super awakeFromNib];

	self.backgroundColor = [UIColor colorWithRed:0xf4/255.0 green:0xf4/255.0 blue:0xf4/255.0 alpha:1.0];
	self.emailLoginButton.backgroundColor = [UIColor colorWithRed:0x76/255.0 green:0xaa/255.0 blue:0xcc/255.0 alpha:1.0];
	[self.emailLoginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[self.emailLoginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
	self.emailLoginButton.layer.cornerRadius = 20.0;
	self.emailLoginButton.contentEdgeInsets = UIEdgeInsetsMake(5.0, 15.0, 5.0, 15.0);

}

@end
