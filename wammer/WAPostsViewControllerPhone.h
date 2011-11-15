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
#import "IRTableViewController.h"

@interface WAPostsViewControllerPhone : IRTableViewController <WAApplicationRootViewController>

- (void) beginCompositionSessionWithContentText:(NSString *)urlString;

@end
