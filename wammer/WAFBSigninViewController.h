//
//  WAFacebookLoginViewController.h
//  wammer
//
//  Created by Shen Steven on 4/11/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAFBSigninViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIImageView *imageView;

- (id) initWithCompletionHandler:(void(^)(NSError *error))completion;
+ (void) backgroundLoginWithFacebookIDWithCompleteHandler:(void(^)(NSError *error))completionHandler;

@end
