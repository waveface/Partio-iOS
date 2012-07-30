//
//  WALocalizedTextView.m
//  wammer
//
//  Created by kchiu on 12/7/27.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WALocalizedTextView.h"

@implementation WALocalizedTextView

- (void) awakeFromNib {
	
	[super awakeFromNib];
	
	self.text = NSLocalizedString(self.text, nil);
	
}

@end
