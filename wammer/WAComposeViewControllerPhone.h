//
//  WAComposeViewControllerPhone.h
//  wammer-iOS
//
//  Created by jamie on 8/11/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "IRTransparentToolbar.h"

@interface WAComposeViewControllerPhone : UIViewController

@property (nonatomic, retain) IBOutlet UITextView *contentTextView;
@property (nonatomic, retain) IBOutlet UIView *contentContainerView;
@property (nonatomic, retain) IBOutlet UIView *attachmentsListViewControllerHeaderView;
@property (nonatomic, retain) IBOutlet IRTransparentToolbar *toolbar;
- (IBAction) handleCameraItemTap:(id)sender;
- (IBAction) handleAttachmentAddFromCameraItemTap:(id)sender;
- (IBAction) handleAttachmentAddFromPhotosLibraryItemTap:(id)sender;

@property (retain, nonatomic) IBOutlet UIButton *AttachmentButton;
- (IBAction)handleAttachmentTap:(id)sender;

+ (WAComposeViewControllerPhone *) controllerWithPost:(NSURL *) aPostURLOrNil completion:(void(^)(NSURL *aPostURLOrNil))aBlock;
+ (WAComposeViewControllerPhone *) controllerWithWebPost:(NSURL *) anURLOrNil completion:(void(^)(NSURL *anURLOrNil))aBlock;
@end
