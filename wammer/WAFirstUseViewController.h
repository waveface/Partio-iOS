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

@property (nonatomic, readwrite, copy) WAFirstUseDidFinish didFinishBlock;
@property (nonatomic, readwrite, copy) WAFirstUseDidAuthSuccess didAuthSuccessBlock;
@property (nonatomic, readwrite, copy) WAFirstUseDidAuthFail didAuthFailBlock;

+ (WAFirstUseViewController *)initWithAuthSuccessBlock:(WAFirstUseDidAuthSuccess)authSuccessBlock
																				 authFailBlock:(WAFirstUseDidAuthFail)authFailBlock
																					 finishBlock:(WAFirstUseDidFinish)finishBlock;

@end
