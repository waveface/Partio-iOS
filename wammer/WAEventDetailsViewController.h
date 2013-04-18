//
//  WAEventDetailsViewController.h
//  wammer
//
//  Created by Shen Steven on 4/18/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAEventDetailsViewController : UITableViewController

+ (id) wrappedNavigationControllerForDetailInfo:(NSDictionary*)detail;
- (id) initWithDetailInfo:(NSDictionary*)detail;
@end
