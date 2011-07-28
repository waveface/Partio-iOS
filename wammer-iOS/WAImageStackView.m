//
//  WAImageStackView.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/28/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAImageStackView.h"
#import "WADataStore.h"


@interface WAImageStackView ()

- (void) waInit;

@end


@implementation WAImageStackView

@synthesize files;

- (id) initWithCoder:(NSCoder *)aDecoder {

	self = [super initWithCoder:aDecoder];
	
	if (!self)
		return nil;
		
	[self waInit];
	
	return self;

}

- (id) initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];
	
	if (!self)
		return nil;
	
	[self waInit];
	
	return self;

}

- (void) waInit {

	[self addObserver:self forKeyPath:@"files" options:NSKeyValueObservingOptionNew context:nil];

}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	if (object == self)
	if ([keyPath isEqualToString:@"files"]) {
	
		for (WAFile *aFile in self.files) {
		
			//	Eh
			
			NSLog(@"has file %@", aFile);
		
		}
	
	}

}

- (void) dealloc {

	[self removeObserver:self forKeyPath:@"files"];
	[super dealloc];

}

@end
