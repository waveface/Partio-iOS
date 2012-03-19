//
//  WAApplicationDidReceiveReadingProgressUpdateNotificationView.m
//  wammer
//
//  Created by Evadne Wu on 12/12/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAApplicationDidReceiveReadingProgressUpdateNotificationView.h"
#import "IRGradientView.h"

@implementation WAApplicationDidReceiveReadingProgressUpdateNotificationView
@synthesize wrapperView;
@synthesize localizableLabels, onAction, onClear;

+ (UIView *) viewFromNib {

  return [[[[UINib nibWithNibName:NSStringFromClass(self) bundle:[NSBundle bundleForClass:self]] instantiateWithOwner:nil options:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    return [evaluatedObject isKindOfClass:self];
  }]] lastObject];

}

- (void) awakeFromNib {

  [super awakeFromNib];
  
	for (UILabel *aLabel in self.localizableLabels)
		aLabel.text = NSLocalizedString(aLabel.text, @"Localized String");
    
  switch ([UIDevice currentDevice].userInterfaceIdiom) {
    
    case UIUserInterfaceIdiomPad: {
      break;
    }
    
    case UIUserInterfaceIdiomPhone: {
    
      for (UILabel *aLabel in self.localizableLabels)
        aLabel.textColor = [UIColor whiteColor];
      
      self.wrapperView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75];
      
      UIView *bottomGlare = [[UIView alloc] initWithFrame:(CGRect){
        (CGPoint){ 0, CGRectGetHeight(self.bounds) - 2 },
        (CGSize){ CGRectGetWidth(self.bounds), 1 }
      }];
      
      bottomGlare.backgroundColor = [UIColor colorWithWhite:1 alpha:0.25];
      bottomGlare.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
      
      [self.wrapperView addSubview:bottomGlare];
      
      
      IRGradientView *backgroundShadowView = [[IRGradientView alloc] initWithFrame:(CGRect){
        (CGPoint){
          CGRectGetMinX(self.wrapperView.bounds),
          CGRectGetMaxY(self.wrapperView.bounds) },
        (CGSize){
          CGRectGetWidth(self.wrapperView.bounds),
          3
        }
      }];
      
      backgroundShadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
      
      [backgroundShadowView setLinearGradientFromColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.35f] anchor:irTop toColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0] anchor:irBottom];
      
      [self.wrapperView addSubview:backgroundShadowView];

      
      break;
      
    }
    
  }

}

- (IBAction) handleAction:(id)sender {

	if (self.onAction)
		self.onAction();
  
}

- (IBAction)handleClear:(id)sender {

  if (self.onClear)
    self.onClear();

}

- (void) enqueueAnimationForVisibility:(BOOL)willBeVisible completion:(void(^)(BOOL didFinish))aBlock {

  [self enqueueAnimationForVisibility:willBeVisible withAdditionalAnimation:nil completion:aBlock];

}

- (void) enqueueAnimationForVisibility:(BOOL)willBeVisible withAdditionalAnimation:(void(^)(void))additionalStuff completion:(void(^)(BOOL didFinish))aBlock {

  [self enqueueAnimationForVisibility:willBeVisible withDuration:0.3 additionalAnimation:additionalStuff completion:aBlock];

}

- (void) enqueueAnimationForVisibility:(BOOL)willBeVisible withDuration:(NSTimeInterval)duration additionalAnimation:(void(^)(void))additionalStuff completion:(void(^)(BOOL didFinish))aBlock {

  CGPoint center = (CGPoint){
    CGRectGetMidX(wrapperView.superview.bounds),
    CGRectGetMidY(wrapperView.superview.bounds)
  };

  CGPoint oldCenter = center;
  CGPoint newCenter = center;

  if (willBeVisible) {
    oldCenter.y -= CGRectGetHeight(wrapperView.bounds);
  } else {
    newCenter.y -= CGRectGetHeight(wrapperView.bounds);
  }
  
  wrapperView.center = oldCenter;
  self.hidden = NO;

  [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction animations:^{
  
    wrapperView.center = newCenter;
    
    if (additionalStuff)
      additionalStuff();

  } completion: ^ (BOOL finished) {
    
    //  wrapperView.center = oldCenter;
    
    if (aBlock)
      aBlock(finished);
    
    self.hidden = !willBeVisible;
    
  }];

}

@end
