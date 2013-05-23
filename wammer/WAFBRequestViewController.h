//
//  WAFBRequestViewController.h
//  wammer
//
//  Created by Shen Steven on 5/21/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAFBRequestViewController : UIViewController
@property (nonatomic, copy) void (^completionHandler)(void);
@end
