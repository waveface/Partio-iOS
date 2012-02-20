//
//  WACompositionViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "AQGridView.h"
#import "IRTransparentToolbar.h"


@class IRImagePickerController, IRAction;

@interface WACompositionViewController : UIViewController

+ (WACompositionViewController *) controllerWithArticle:(NSURL *)anArticleURLOrNil completion:(void(^)(NSURL *anArticleURLOrNil))aBlock;

@property (nonatomic, readwrite, retain) IBOutlet UIView *containerView;
- (void) adjustContainerViewWithInterfaceBounds:(CGRect)newBounds;

@property (nonatomic, readwrite, retain) IBOutlet AQGridView *photosView;
@property (nonatomic, readwrite, retain) IBOutlet UITextView *contentTextView;
@property (nonatomic, readwrite, retain) IBOutlet IRTransparentToolbar *toolbar;
@property (nonatomic, readwrite, retain) IBOutlet UIView *noPhotoReminderView;

@property (nonatomic, readwrite, retain) IBOutletCollection(id) NSArray *noPhotoReminderViewElements;

- (IBAction) handleCameraItemTap:(UIButton *)sender;

@property (nonatomic, readwrite, assign) BOOL usesTransparentBackground;

- (IRImagePickerController *) newImagePickerController NS_RETURNS_RETAINED;
- (IRImagePickerController *) newCameraCapturePickerController NS_RETURNS_RETAINED;

- (IRAction *) newPresentImagePickerControllerActionWithSender:(id)sender NS_RETURNS_RETAINED;
- (IRAction *) newPresentCameraCaptureControllerActionWithSender:(id)sender NS_RETURNS_RETAINED;

@end


@interface WACompositionViewController (SubclassResponsibility)

- (IBAction) handlePreviewBadgeTap:(id)sender;

- (void) presentImagePickerController:(IRImagePickerController *)controller sender:(id)sender;
- (void) presentCameraCapturePickerController:(IRImagePickerController *)controller sender:(id)sender;

- (void) dismissImagePickerController:(IRImagePickerController *)controller;
- (void) dismissCameraCapturePickerController:(IRImagePickerController *)controller;

@end