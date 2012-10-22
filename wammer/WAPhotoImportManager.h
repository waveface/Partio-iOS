//
//  WAPhotoImportManager.h
//  wammer
//
//  Created by kchiu on 12/9/11.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WAArticle.h"

@interface WAPhotoImportManager : NSObject

@property (nonatomic, readwrite) BOOL enabled;

- (void)createPhotoImportArticlesWithCompletionBlock:(void(^)(void))aCallbackBlock;
- (void)waitUntilFinished;

@end
