//
//  WASyncManager+PhotoImport.h
//  wammer
//
//  Created by kchiu on 12/12/24.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WASyncManager.h"

@class IRAsyncOperation;
@interface WASyncManager (PhotoImport)

- (IRAsyncOperation *) photoImportOperation;

@end
