//
//  WAFetchManager+RemoteChangeFetch.h
//  wammer
//
//  Created by kchiu on 12/12/28.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFetchManager.h"

@class IRAsyncOperation;
@interface WAFetchManager (RemoteChangeFetch)

- (IRAsyncOperation *)remoteChangeFetchOperationPrototype;

@end
