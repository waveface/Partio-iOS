//
//  WANavigationBar.m
//  wammer
//
//  Created by Evadne Wu on 10/4/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WANavigationBar.h"
#import "IRGradientView.h"

@interface WANavigationBar ()

- (void) sharedInit;

@end


@implementation WANavigationBar

- (id) initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];
	if (!self)
		return nil;
	
	[self sharedInit];
	
	return self;

}

- (id) initWithCoder:(NSCoder *)aDecoder {

	self = [super initWithCoder:aDecoder];
	if (!self)
		return nil;

	[self sharedInit];
	
	return self;

}

- (void) awakeFromNib {

	[super awakeFromNib];
	
	[self sharedInit];

}

- (void) sharedInit {

	IRGradientView *backgroundGradientView = [[[IRGradientView alloc] initWithFrame:self.bounds] autorelease];
	backgroundGradientView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[backgroundGradientView setLinearGradientFromColor:[UIColor colorWithRed:.95 green:.95 blue:.95 alpha:.95] anchor:irTop toColor:[UIColor colorWithRed:.7 green:.7 blue:.7 alpha:.95] anchor:irBottom];
	
	UIView *backgroundGlareView = [[[UIView alloc] initWithFrame:(CGRect){
		(CGPoint){ CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds) - 1 },
		(CGSize){ CGRectGetWidth(self.bounds), 1 }
	}] autorelease];
	backgroundGlareView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
	backgroundGlareView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:.25];
	
	IRGradientView *backgroundShadowView = [[[IRGradientView alloc] initWithFrame:(CGRect){
		(CGPoint){ CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds) },
		(CGSize){ CGRectGetWidth(self.bounds), 3 }
	}] autorelease];
	backgroundShadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[backgroundShadowView setLinearGradientFromColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.35f] anchor:irTop toColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0] anchor:irBottom];
	
	[self addSubview:backgroundShadowView];
	[self addSubview:backgroundGradientView];
	[self addSubview:backgroundGlareView];

	[self sendSubviewToBack:backgroundGradientView];
	[self sendSubviewToBack:backgroundShadowView];

}

- (void) drawRect:(CGRect)rect {
		
		//	Nope.
		
}

@end
