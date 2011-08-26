//
//  WATableViewCell.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/26/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WATableViewCell.h"

@implementation WATableViewCell
@synthesize onSetSelected, onSetEditing;

- (void) setSelected:(BOOL)selected animated:(BOOL)animated {
	
	[super setSelected:selected animated:animated];
	
	if (self.onSetSelected)
		self.onSetSelected(self, selected, animated);
	
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {

	[super setEditing:editing animated:animated];
	
	if (self.onSetEditing)
		self.onSetEditing(self, editing, animated);
		
}

- (void) dealloc {

	[onSetSelected release];
	[onSetEditing release];
	[super dealloc];

}

@end
