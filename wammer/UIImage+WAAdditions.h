//
//  UIImage+WAAdditions.h
//  wammer
//
//  Created by kchiu on 12/12/20.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAImageProcessing.h"

@interface UIImage (WAAdditions)

- (void)makeThumbnailWithOptions:(WAThumbnailType)type completeBlock:(WAImageProcessComplete)didCompleteBlock;
- (void)makeBlurredImageWithCompleteBlock:(WAImageProcessComplete)didCompleteBlock;

@end
