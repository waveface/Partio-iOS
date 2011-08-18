//
//  WAPostViewController.h
//  wammer-iOS
//
//  Created by jamie on 8/11/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAArticle.h"

@interface WAPostViewControllerPhone : UITableViewController

+ (WAPostViewControllerPhone *) controllerWithPost:(NSURL *)postURL;

@end
