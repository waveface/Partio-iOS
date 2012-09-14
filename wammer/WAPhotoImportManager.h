//
//  WAPhotoImportManager.h
//  wammer
//
//  Created by kchiu on 12/9/11.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WAArticle.h"

typedef void (^WAPhotoImportCallback) ();

@interface WAPhotoImportManager : NSObject

@property (nonatomic, readwrite, assign) BOOL running;
@property (nonatomic, readwrite, strong) WAArticle *lastImportedArticle;

+ (WAPhotoImportManager *)defaultManager;

- (void)createPhotoImportArticlesWithCompletionBlock:(WAPhotoImportCallback)aCallbackBlock;

@end
