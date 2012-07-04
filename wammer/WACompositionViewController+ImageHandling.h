//
//  WACompositionViewController+ImageHandling.h
//  wammer
//
//  Created by Evadne Wu on 2/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WACompositionViewController.h"


@class ALAsset;
@interface WACompositionViewController (ImageHandling)

- (IRImagePickerController *) newImagePickerController;
- (IRImagePickerController *) newCameraCapturePickerController;

- (void) handleImageAttachmentInsertionRequestWithSender:(id)sender;
- (void) handleImageAttachmentInsertionRequestWithOptions:(NSDictionary *)options sender:(id)sender;

- (void) presentImagePickerController:(IRImagePickerController *)controller sender:(id)sender animated:(BOOL)animated;
- (void) dismissImagePickerController:(IRImagePickerController *)controller animated:(BOOL)animated;

- (void) presentCameraCapturePickerController:(IRImagePickerController *)controller sender:(id)sender animated:(BOOL)animated;
- (void) dismissCameraCapturePickerController:(IRImagePickerController *)controller animated:(BOOL)animated;

- (void) handleIncomingSelectedAssetImage:(UIImage *)image URI:(NSURL *)aFileURL representedAsset:(ALAsset *)photoLibraryAsset;

- (BOOL) shouldDismissSelfOnCameraCancellation;

- (void) handleSelectionWithArray: (NSArray *)selectedAssets;

@end

extern NSString * const WACompositionImageInsertionUsesCamera;
extern NSString * const WACompositionImageInsertionAnimatePresentation;
extern NSString * const WACompositionImageInsertionCancellationTriggersSessionTermination;