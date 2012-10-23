//
//  WAArticlesViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>

#import "WAApplicationRootViewControllerDelegate.h"
#import "UIKit+IRAdditions.h"
#import "WASlidingMenuViewController.h"
#import "IIViewDeckController.h"
#import "WADayViewController.h"

@interface WATimelineViewControllerPhone : IRTableViewController <WAApplicationRootViewController>

- (id) initWithDate:(NSDate*)date;

@end
