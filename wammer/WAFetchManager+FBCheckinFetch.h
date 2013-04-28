//
//  WAFetchManager+FBCheckinFetch.h
//  wammer
//
//  Created by Shen Steven on 4/27/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAFetchManager.h"

@class IRAsyncOperation;
@interface WAFetchManager (FBCheckinFetch)

- (IRAsyncOperation *)fbCheckinFetchPrototype;

@end
