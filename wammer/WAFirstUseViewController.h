//
//  WAFirstUseViewController.h
//  wammer
//
//  Created by kchiu on 12/10/24.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAFirstUseViewController : UINavigationController

@property (nonatomic, readwrite, strong) void(^completeBlock)(void);

+ (WAFirstUseViewController *)initWithCompleteBlock:(void(^)(void))completeBlock;

@end
