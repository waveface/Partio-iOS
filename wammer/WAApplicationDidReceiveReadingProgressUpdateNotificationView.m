//
//  WAApplicationDidReceiveReadingProgressUpdateNotificationView.m
//  wammer
//
//  Created by Evadne Wu on 12/12/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAApplicationDidReceiveReadingProgressUpdateNotificationView.h"

@implementation WAApplicationDidReceiveReadingProgressUpdateNotificationView
@synthesize localizableLabels, onAction;

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
	[super dealloc];
	
}

- (IBAction) handleAction:(id)sender {

	if (self.onAction)
		self.onAction();
}

@end
