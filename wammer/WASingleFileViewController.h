//
//  WASingleFileViewController.h
//  wammer
//
//  Created by Evadne Wu on 12/5/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

@interface WASingleFileViewController : QLPreviewController

+ (id) controllerForFile:(NSURL *)aFileURI;

@property (retain, nonatomic) IBOutlet UIProgressView *progressView;
@property (retain, nonatomic) IBOutlet UILabel *fileLoadingLabel;
@property (retain, nonatomic) IBOutlet UILabel *fileLoadingProgressLabel;

@property (nonatomic, readwrite, copy) void (^onFinishLoad)(WASingleFileViewController *self);

@end




@interface WASingleFileViewController (QuickLook) <QLPreviewControllerDelegate, QLPreviewControllerDataSource>

+ (void(^)(WASingleFileViewController *self)) defaultQuickLookFinishLoadHandler;

@end
