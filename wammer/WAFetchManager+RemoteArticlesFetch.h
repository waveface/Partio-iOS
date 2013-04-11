//
//  WAFetchManager+RemoteArticlesFetch.h
//  wammer
//
//  Created by Shen Steven on 4/11/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAFetchManager.h"

@class IRAsyncOperation;
@interface WAFetchManager (RemoteArticlesFetch)

- (IRAsyncOperation *)remoteArticlesFetchOperationPrototype;

@end
