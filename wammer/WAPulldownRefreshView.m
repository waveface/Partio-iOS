//
//  WAPulldownRefreshView.m
//  wammer
//
//  Created by Evadne Wu on 9/21/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAPulldownRefreshView.h"
#import "IRGradientView.h"
#import "CGGeometry+IRAdditions.h"
#import "QuartzCore+IRAdditions.h"


@implementation WAPulldownRefreshView
@synthesize progress, arrowView, spinner, busy;

+ (id) viewFromNib {

	return [[[[UINib nibWithNibName:NSStringFromClass(self) bundle:[NSBundle bundleForClass:self]] instantiateWithOwner:nil options:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock: ^ (id evaluatedObject, NSDictionary *bindings) {
		return [evaluatedObject isKindOfClass:self];
	}]] lastObject];

}

- (void) awakeFromNib {

	[super awakeFromNib];
	
	UIView *highlight = [[[UIView alloc] initWithFrame:IRGravitize(
		self.bounds, 
		(CGSize){ CGRectGetWidth(self.bounds), 1},
		kCAGravityBottom
	)] autorelease];
	
	highlight.frame = CGRectOffset(highlight.frame, 0, 1);
	highlight.backgroundColor = [UIColor colorWithWhite:1 alpha:0.125];
	highlight.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
	
	[self addSubview:highlight];
	[self sendSubviewToBack:highlight];
	
	
	UIView *lining = [[[UIView alloc] initWithFrame:IRGravitize(
		self.bounds, 
		(CGSize){ CGRectGetWidth(self.bounds), 1},
		kCAGravityBottom
	)] autorelease];
	
	lining.backgroundColor = [UIColor colorWithWhite:0 alpha:0.125];
	lining.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
	
	[self addSubview:lining];
	[self sendSubviewToBack:lining];
	
		
	IRGradientView *pulldownHeaderBackgroundShadow = [[[IRGradientView alloc] initWithFrame:IRGravitize(
		self.bounds,
		(CGSize){ CGRectGetWidth(self.bounds), 3 },
		kCAGravityBottom
	)] autorelease];
	
	pulldownHeaderBackgroundShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
	
	UIColor *fromColor = [UIColor colorWithWhite:0 alpha:0];
	UIColor *toColor = [UIColor colorWithWhite:0 alpha:0.125];
	[pulldownHeaderBackgroundShadow setLinearGradientFromColor:fromColor anchor:irTop toColor:toColor anchor:irBottom];
		
	[self addSubview:pulldownHeaderBackgroundShadow];
	[self sendSubviewToBack:pulldownHeaderBackgroundShadow];
	
	
	UIView *pulldownHeaderBackground = [[[UIView alloc] initWithFrame:UIEdgeInsetsInsetRect(self.bounds, (UIEdgeInsets){ -256, 0, 0, 0 })] autorelease];
	pulldownHeaderBackground.backgroundColor = [UIColor colorWithWhite:0 alpha:0.125];
	
	[self addSubview:pulldownHeaderBackground];
	[self sendSubviewToBack:pulldownHeaderBackground];
	
	
  [self.spinner startAnimating];
  [self.spinner setHidesWhenStopped:NO];
  
  [self setNeedsLayout];

}

- (void) setProgress:(CGFloat)newProgress {

	if (progress == newProgress)
		return;
	
	[self willChangeValueForKey:@"progress"];
	progress = newProgress;
	[self didChangeValueForKey:@"progress"];
  
	[self setNeedsLayout];

}

- (void) setProgress:(CGFloat)newProgress animated:(BOOL)animate {

  NSTimeInterval animationDuration = animate ? 0.3 : 0.0;
  NSTimeInterval animationDelay = 0;
  UIViewAnimationOptions animationOptions = UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState;
  
  [UIView animateWithDuration:animationDuration delay:animationDelay options:animationOptions animations:^{
    
    [self setProgress:newProgress];
    [self layoutSubviews];
    [self setNeedsLayout];
    
  } completion:nil]; 

}

- (void) setBusy:(BOOL)newBusy {

  if (busy == newBusy)
    return;
  
  [self willChangeValueForKey:@"isBusy"];
  busy = newBusy;
  [self didChangeValueForKey:@"isBusy"];
  
  [self setNeedsLayout];
  
  //  Implicit layout?

}

- (void) setBusy:(BOOL)flag animated:(BOOL)animate {

  NSTimeInterval animationDuration = animate ? 0.3 : 0.0;
  NSTimeInterval animationDelay = 0;
  UIViewAnimationOptions animationOptions = UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState;
  
  [UIView animateWithDuration:animationDuration delay:animationDelay options:animationOptions animations:^{
    
    [self setBusy:flag];
    [self layoutSubviews];
    [self setNeedsLayout];
    
  } completion:nil];

}

- (void) layoutSubviews {

	[super layoutSubviews];
  
  CGFloat rotatedDegrees = (progress >= 0.5) ? 180.0f : 360.0f;
  CGFloat rotatedRadians = 2 * M_PI * (rotatedDegrees / 360.0f);
	
  self.arrowView.transform = CGAffineTransformMakeRotation(rotatedRadians); //CATransform3DMakeRotation(rotatedRadians, 0, 0, 1);
  
  if (busy) {
  
    self.arrowView.alpha = 0;
    self.spinner.alpha = 1;
  
  } else {
  
    self.arrowView.alpha = 1;
    self.spinner.alpha = 0;
  
  }

}

- (void) dealloc {
  
  [arrowView release];
  [spinner release];
  [super dealloc];

}

@end
