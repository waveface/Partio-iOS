//
//  WASyncManager+FileMetadataSync.h
//  wammer
//
//  Created by kchiu on 12/11/12.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WASyncManager.h"

@interface WASyncManager (FileMetadataSync)

- (IRAsyncOperation *) fileMetadataSyncOperationPrototype;

@end
