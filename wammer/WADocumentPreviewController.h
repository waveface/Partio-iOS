//
//  WADocumentPreviewController.h
//  wammer
//
//  Created by kchiu on 12/12/13.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>
#import "WAFile.h"

@interface WADocumentPreviewController : QLPreviewController <QLPreviewControllerDataSource, QLPreviewControllerDelegate>

- (WADocumentPreviewController *) initWithFile:(WAFile *)file;

@end
