//
//  WAPhotoImportManager.h
//  wammer
//
//  Created by kchiu on 12/9/11.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^WAPhotoImportCallback) ();

@interface WAPhotoImportManager : NSObject

@property (nonatomic, readwrite, assign) BOOL running;

+ (WAPhotoImportManager *)defaultManager;

- (void)createPhotoImportArticlesWithCompletionBlock:(WAPhotoImportCallback)aCallbackBlock;

@end
