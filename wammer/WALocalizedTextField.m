//
//  WALocalizedTextField.m
//  wammer
//
//  Created by Evadne Wu on 7/20/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WALocalizedTextField.h"

@implementation WALocalizedTextField

- (void) awakeFromNib {

	[super awakeFromNib];
	
	self.text = NSLocalizedString(self.text, nil);
	self.placeholder = NSLocalizedString(self.placeholder, nil);

}

@end
