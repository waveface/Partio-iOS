//
//  WALocalizedButton.m
//  wammer
//
//  Created by Evadne Wu on 3/8/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WALocalizedButton.h"

@implementation WALocalizedButton

- (void) awakeFromNib {

	[super awakeFromNib];
	
	void (^massage)(UIControlState) = ^ (UIControlState state) {
	
		NSString *title = [self titleForState:state];
		if (!title)
			return;
		
		[self setTitle:NSLocalizedString(title, nil) forState:state];
	
	};
	
	massage(UIControlStateApplication);
	massage(UIControlStateDisabled);
	massage(UIControlStateHighlighted);
	massage(UIControlStateNormal);
	massage(UIControlStateReserved);
	massage(UIControlStateSelected);
	
}
@end
