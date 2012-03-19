//
//  WANavigationBar.m
//  wammer
//
//  Created by Evadne Wu on 10/4/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WANavigationBar.h"
#import "IRGradientView.h"
#import "IRLifetimeHelper.h"

@interface WANavigationBar ()

- (void) sharedInit;

@end


@implementation WANavigationBar
@synthesize customBackgroundView;
@synthesize suppressesDefaultAppearance;
@synthesize onBarStyleContextChanged;

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

	self.backgroundColor = nil;
	self.opaque = NO;
  self.suppressesDefaultAppearance = NO;

}

- (void) drawRect:(CGRect)rect {
  
  if (self.suppressesDefaultAppearance) {
  
  } else {
  
    [super drawRect:rect];
  
  }
		
}

- (void) setCustomBackgroundView:(UIView *)newCustomBackgroundView {

	if (customBackgroundView == newCustomBackgroundView)
		return;
	
	if ([customBackgroundView isDescendantOfView:self])
		[customBackgroundView removeFromSuperview];
		
	customBackgroundView = newCustomBackgroundView;
	
	customBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	customBackgroundView.frame = self.bounds;
  
  customBackgroundView.userInteractionEnabled = NO;
	
	[self addSubview:customBackgroundView];
	[self sendSubviewToBack:customBackgroundView];

  self.suppressesDefaultAppearance = (BOOL)!!(customBackgroundView);

}

- (void) layoutSubviews {

  [super layoutSubviews];
  
  [self.customBackgroundView.superview sendSubviewToBack:self.customBackgroundView];
  
}

- (void) setSuppressesDefaultAppearance:(BOOL)flag {

  suppressesDefaultAppearance = flag;
  
  [self setNeedsDisplay];

}

- (void) setBarStyle:(UIBarStyle)newBarStyle {

	BOOL barStyleChanged = (self.barStyle != newBarStyle);

	[super setBarStyle:newBarStyle];
	
	if (barStyleChanged)
	if (self.onBarStyleContextChanged)
		self.onBarStyleContextChanged();

}

- (void) setTranslucent:(BOOL)newFlag {

	BOOL translucentFlagChanged = (self.translucent != newFlag);
	
	[super setTranslucent:newFlag];
	
	if (translucentFlagChanged)
	if (self.onBarStyleContextChanged)
		self.onBarStyleContextChanged();

}

+ (UIView *) defaultGradientBackgroundView {

	UIView *returnedView = [[UIView alloc] initWithFrame:(CGRect){ CGPointZero, (CGSize){ 512, 44 }}];

	IRGradientView *backgroundGradientView = [[IRGradientView alloc] initWithFrame:returnedView.bounds];
	backgroundGradientView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[backgroundGradientView setLinearGradientFromColor:[UIColor colorWithRed:.95 green:.95 blue:.95 alpha:.95] anchor:irTop toColor:[UIColor colorWithRed:.7 green:.7 blue:.7 alpha:.95] anchor:irBottom];
	
	UIView *backgroundGlareView = [[UIView alloc] initWithFrame:(CGRect){
		(CGPoint){ CGRectGetMinX(returnedView.bounds), CGRectGetMaxY(returnedView.bounds) - 1 },
		(CGSize){ CGRectGetWidth(returnedView.bounds), 1 }
	}];
	backgroundGlareView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
	backgroundGlareView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:.25];
	
	IRGradientView *backgroundShadowView = [[IRGradientView alloc] initWithFrame:(CGRect){
		(CGPoint){ CGRectGetMinX(returnedView.bounds), CGRectGetMaxY(returnedView.bounds) },
		(CGSize){ CGRectGetWidth(returnedView.bounds), 3 }
	}];
	backgroundShadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
	[backgroundShadowView setLinearGradientFromColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.35f] anchor:irTop toColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0] anchor:irBottom];
	
	[returnedView addSubview:backgroundShadowView];
	[returnedView addSubview:backgroundGradientView];
	[returnedView addSubview:backgroundGlareView];
  
  returnedView.userInteractionEnabled = NO;

	return returnedView;

}

+ (UIView *) defaultPatternBackgroundView {

  UIImage *backdropImage = [UIImage imageNamed:@"WANavigationBarBackdrop"];
  UIImage *landscapeBackdropImage = [UIImage imageNamed:@"WANavigationBarBackdropLandscape"];
  UIView *returnedView = [[UIView alloc] initWithFrame:CGRectZero];
  
  returnedView.backgroundColor = [UIColor colorWithPatternImage:backdropImage];
  returnedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  
	
	BOOL (^isPhone)(void) = ^ {
		
		return (BOOL)([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone);
		
	};
	
	void (^updateBarImage)(UIInterfaceOrientation) = ^ (UIInterfaceOrientation anOrientation) {
	
		BOOL landscapePhone = (isPhone()) && UIInterfaceOrientationIsLandscape(anOrientation);
		UIImage *image = landscapePhone ? landscapeBackdropImage : backdropImage;
		
		returnedView.backgroundColor = [UIColor colorWithPatternImage:image];
		
	};
	
	if (isPhone()) {
	
		__weak id notificationObject = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidChangeStatusBarOrientationNotification object:nil queue:nil usingBlock: ^ (NSNotification *note) {
		
			updateBarImage([UIApplication sharedApplication].statusBarOrientation);
			
		}];
		
		[returnedView irPerformOnDeallocation:^{
			
			[[NSNotificationCenter defaultCenter] removeObserver:notificationObject];
			
		}];
	
	}
	
	updateBarImage([UIApplication sharedApplication].statusBarOrientation);
	
	
  UIView *topGlare = [[UIView alloc] initWithFrame:(CGRect){
    (CGPoint){ 0, 0 },
    (CGSize){ CGRectGetWidth(returnedView.bounds), 1 }
  }];
  
  topGlare.backgroundColor = [UIColor colorWithWhite:1 alpha:0.25];
  topGlare.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
  
  [returnedView addSubview:topGlare];
  
  
  UIView *bottomGlare = [[UIView alloc] initWithFrame:(CGRect){
    (CGPoint){ 0, CGRectGetHeight(returnedView.bounds) - 1 },
    (CGSize){ CGRectGetWidth(returnedView.bounds), 1 }
  }];
  
  bottomGlare.backgroundColor = [UIColor colorWithWhite:0 alpha:0.25];
  bottomGlare.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
  
  [returnedView addSubview:bottomGlare];
	
	
	IRGradientView *bottomShadow = [[IRGradientView alloc] initWithFrame:(CGRect){
		(CGPoint){ CGRectGetMinX(returnedView.bounds), CGRectGetMaxY(returnedView.bounds) },
		(CGSize){ CGRectGetWidth(returnedView.bounds), 3 }
	}];
	bottomShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
	[bottomShadow setLinearGradientFromColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.25f] anchor:irTop toColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0] anchor:irBottom];
	
	[returnedView addSubview:bottomShadow];
  
  return (UIView *)returnedView;

}

@end
