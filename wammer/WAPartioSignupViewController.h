//
//  WAPartioSignupViewController.h
//  wammer
//
//  Created by Shen Steven on 4/16/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAPartioSignupViewController : UIViewController
@property (nonatomic, copy) void (^completeHandler)(NSError *error);
- (id)initWithCompleteHandler:(void(^)(NSError *error))completeHandler;
@end
