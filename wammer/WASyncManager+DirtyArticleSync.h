//
//  WASyncManager+DirtyArticleSync.h
//  wammer
//
//  Created by Evadne Wu on 6/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WASyncManager.h"

@class IRAsyncOperation;
@interface WASyncManager (DirtyArticleSync)

- (IRAsyncOperation *) dirtyArticleSyncOperationPrototype;

@end
