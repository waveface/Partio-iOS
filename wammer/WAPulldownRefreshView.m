//
//  WAPulldownRefreshView.m
//  wammer
//
//  Created by Evadne Wu on 9/21/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAPulldownRefreshView.h"


@implementation WAPulldownRefreshView
@synthesize progress, arrowView, spinner, busy;

+ (id) viewFromNib {

	return [[[[UINib nibWithNibName:NSStringFromClass(self) bundle:[NSBundle bundleForClass:self]] instantiateWithOwner:nil options:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock: ^ (id evaluatedObject, NSDictionary *bindings) {
		return [evaluatedObject isKindOfClass:self];
	}]] lastObject];

}

- (void) awakeFromNib {

	[super awakeFromNib];
  
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
