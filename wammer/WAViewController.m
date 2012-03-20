//
//  WAViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/10/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAViewController.h"

@implementation WAViewController

@synthesize onShouldAutorotateToInterfaceOrientation, onLoadview;
@synthesize onViewWillAppear, onViewDidAppear, onViewWillDisappear, onViewDidDisappear;

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

	if (self.onShouldAutorotateToInterfaceOrientation)
		return self.onShouldAutorotateToInterfaceOrientation(interfaceOrientation);

	return (interfaceOrientation == UIInterfaceOrientationPortrait);
	
}

- (void) loadView {

	if (self.onLoadview)
		self.onLoadview(self);
	else
		[super loadView];

}

- (void) viewWillAppear:(BOOL)animated {
  
  [super viewWillAppear:animated];
  
  if (self.onViewWillAppear)
    self.onViewWillAppear(self);
    
}

- (void) viewDidAppear:(BOOL)animated {

  [super viewDidAppear:animated];
  
  if (self.onViewDidAppear)
    self.onViewDidAppear(self);

}

- (void) viewWillDisappear:(BOOL)animated {

  [super viewWillDisappear:animated];
  
  if (self.onViewWillDisappear)
    self.onViewWillDisappear(self);

}

- (void) viewDidDisappear:(BOOL)animated {

  [super viewDidDisappear:animated];
  
  if (self.onViewDidDisappear)
    self.onViewDidDisappear(self);

}

@end
