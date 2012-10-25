//
//  WADayHeaderView.m
//  wammer
//
//  Created by Shen Steven on 10/23/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADayHeaderView.h"

@implementation WADayHeaderView

+ (id) viewFromNib {
	
	return [[[[UINib nibWithNibName:NSStringFromClass(self) bundle:[NSBundle bundleForClass:self]] instantiateWithOwner:nil options:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock: ^ (id evaluatedObject, NSDictionary *bindings) {
		return [evaluatedObject isKindOfClass:self];
	}]] lastObject];
	
}

- (void) awakeFromNib {
	
}


@end
