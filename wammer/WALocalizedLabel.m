//
//  WALocalizedLabel.m
//  wammer
//
//  Created by Evadne Wu on 3/8/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WALocalizedLabel.h"

@implementation WALocalizedLabel

- (void) awakeFromNib {

	[super awakeFromNib];
	
	self.text = NSLocalizedString(self.text, nil);
	
}

@end
