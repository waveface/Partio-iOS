//
//  WAPartioWelcomViewController.h
//  wammer
//
//  Created by Shen Steven on 4/6/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAPartioFirstUseViewController : UINavigationController

@property (nonatomic, copy) void (^completionBlock)(void);
@property (nonatomic, copy) void (^failureBlock)(NSError *);

+ (WAPartioFirstUseViewController*) firstUseViewControllerWithCompletionBlock:(void(^)(void))completion failure:(void(^)(NSError*))failure;

@end
