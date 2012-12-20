//
//  WAImageProcessing.h
//  wammer
//
//  Created by kchiu on 12/12/18.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WADefines.h"

typedef void(^WAImageProcessComplete)(UIImage *image);

@interface WAImageProcessing : NSObject

+ (UIImage *)scaledImageWithCGImage:(CGImageRef)image type:(WAThumbnailType)type orientation:(UIImageOrientation)orientation;

+ (NSOperationQueue *)sharedImageProcessQueue;

@end
