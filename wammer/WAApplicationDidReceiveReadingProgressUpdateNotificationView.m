//
//  WAApplicationDidReceiveReadingProgressUpdateNotificationView.m
//  wammer
//
//  Created by Evadne Wu on 12/12/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAApplicationDidReceiveReadingProgressUpdateNotificationView.h"

@implementation WAApplicationDidReceiveReadingProgressUpdateNotificationView
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
      
      self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75];
      
      UIView *bottomGlare = [[[UIView alloc] initWithFrame:(CGRect){
        (CGPoint){ 0, CGRectGetHeight(self.bounds) - 2 },
        (CGSize){ CGRectGetWidth(self.bounds), 1 }
      }] autorelease];
      
      bottomGlare.backgroundColor = [UIColor colorWithWhite:1 alpha:0.25];
      bottomGlare.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
      
      [self addSubview:bottomGlare];
      
      break;
      
    }
    
  }

}

- (void) dealloc {
	
	[localizableLabels release];
	[onAction release];
  [onClear release];
	[super dealloc];
	
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

  CGPoint oldCenter = self.center;
  CGPoint newCenter = oldCenter;

  if (willBeVisible) {
    oldCenter.y -= CGRectGetHeight(self.bounds);
  } else {
    newCenter.y -= CGRectGetHeight(self.bounds);
  }
  
  self.center = oldCenter;
  self.hidden = NO;

  [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction animations:^{

    self.center = newCenter;
    
  } completion: ^ (BOOL finished) {
    
    if (aBlock)
      aBlock(finished);
    
    self.hidden = !willBeVisible;
    
  }];

}

@end
