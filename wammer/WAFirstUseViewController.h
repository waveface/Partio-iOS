//
//  WAFirstUseViewController.h
//  wammer
//
//  Created by kchiu on 12/10/24.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAFirstUseViewController : UINavigationController

typedef void (^WAFirstUseDidFinish)(void);
typedef void (^WAFirstUseDidAuthSuccess)(NSString *token, NSDictionary *userRep, NSArray *groupReps);
typedef void (^WAFirstUseDidAuthFail)(NSError *error);

@property (nonatomic, readwrite, strong) WAFirstUseDidFinish didFinishBlock;
@property (nonatomic, readwrite, strong) WAFirstUseDidAuthSuccess didAuthSuccessBlock;
@property (nonatomic, readwrite, strong) WAFirstUseDidAuthFail didAuthFailBlock;

+ (WAFirstUseViewController *)initWithAuthSuccessBlock:(WAFirstUseDidAuthSuccess)authSuccessBlock
																				 authFailBlock:(WAFirstUseDidAuthFail)authFailBlock
																					 finishBlock:(WAFirstUseDidFinish)finishBlock;

@end
