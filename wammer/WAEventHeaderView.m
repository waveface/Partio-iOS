//
//  WAEventHeaderView.m
//  wammer
//
//  Created by Shen Steven on 11/6/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAEventHeaderView.h"

@implementation WAEventHeaderView

+ (id) viewFromNib {
	
	__weak id wSelf = self;
	return [[[[UINib nibWithNibName:NSStringFromClass(self) bundle:[NSBundle bundleForClass:self]] instantiateWithOwner:nil options:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock: ^ (id evaluatedObject, NSDictionary *bindings) {
		return [evaluatedObject isKindOfClass:wSelf];
	}]] lastObject];
	
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

@end
