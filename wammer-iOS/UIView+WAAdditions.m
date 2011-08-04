//
//  UIView+WAAdditions.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/3/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "UIView+WAAdditions.h"

@implementation UIView (WAAdditions)

- (UIView *) waFirstResponderInView {

	if (self.isFirstResponder)
		return self;
	
	for (UIView *aSubview in self.subviews) {
		UIView *foundFirstResponder = [aSubview waFirstResponderInView];
		if (foundFirstResponder)
			return foundFirstResponder;
	}
	
	return nil;

}

@end
