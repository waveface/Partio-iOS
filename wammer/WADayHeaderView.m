//
//  WADayHeaderView.m
//  wammer
//
//  Created by Shen Steven on 10/23/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADayHeaderView.h"

NSString * const kWADayHeaderViewID = @"WADayHeaderView";

@implementation WADayHeaderView

- (id)initWithFrame:(CGRect)frame {

	self = [[self class] viewFromNib];

	return self;

}

+ (id) viewFromNib {
	
	return [[[[UINib nibWithNibName:NSStringFromClass(self) bundle:[NSBundle bundleForClass:self]] instantiateWithOwner:nil options:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock: ^ (id evaluatedObject, NSDictionary *bindings) {
		return [evaluatedObject isKindOfClass:self];
	}]] lastObject];
	
}

- (void) awakeFromNib {
  self.placeHolderView.layer.cornerRadius = 5.0f;
  self.placeHolderView.layer.masksToBounds = YES;
}


@end
