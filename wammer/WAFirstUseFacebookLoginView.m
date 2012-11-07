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

@end
