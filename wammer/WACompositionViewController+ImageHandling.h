//
//  WACompositionViewController+ImageHandling.h
//  wammer
//
//  Created by Evadne Wu on 2/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WACompositionViewController.h"
#import "WAFile.h"


@class ALAsset;
@interface WACompositionViewController (ImageHandling)

- (IRImagePickerController *) newImagePickerController;
- (IRImagePickerController *) newCameraCapturePickerController;

- (void) handleImageAttachmentInsertionRequestWithSender:(id)sender;
- (void) handleImageAttachmentInsertionRequestWithOptions:(NSDictionary *)options sender:(id)sender;

- (void) presentImagePickerController:(UIViewController *)controller sender:(id)sender animated:(BOOL)animated;
- (void) dismissImagePickerController:(UIViewController *)controller animated:(BOOL)animated;

- (void) presentCameraCapturePickerController:(UIViewController *)controller sender:(id)sender animated:(BOOL)animated;
- (void) dismissCameraCapturePickerController:(UIViewController *)controller animated:(BOOL)animated;

- (void) makeAssociatedImagesOfFile:(WAFile *)file withResourceImage:(UIImage *)resourceImage representedAsset:(ALAsset *)representedAsset;
- (void) handleIncomingSelectedAssetImage:(UIImage *)image representedAsset:(ALAsset *)photoLibraryAsset;

- (BOOL) shouldDismissSelfOnCameraCancellation;

- (void) handleSelectionWithArray: (NSArray *)selectedAssets;

@end

extern NSString * const WACompositionImageInsertionUsesCamera;
extern NSString * const WACompositionImageInsertionAnimatePresentation;
extern NSString * const WACompositionImageInsertionCancellationTriggersSessionTermination;