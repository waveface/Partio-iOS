//
//  WACompositionViewController+ImageHandling.h
//  wammer
//
//  Created by Evadne Wu on 2/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WACompositionViewController.h"

@interface WACompositionViewController (ImageHandling)

- (IRImagePickerController *) newImagePickerController NS_RETURNS_RETAINED;
- (IRImagePickerController *) newCameraCapturePickerController NS_RETURNS_RETAINED;

- (IRAction *) newPresentImagePickerControllerActionWithSender:(id)sender NS_RETURNS_RETAINED;
- (IRAction *) newPresentCameraCaptureControllerActionWithSender:(id)sender NS_RETURNS_RETAINED;

- (void) handleImageAttachmentInsertionRequestWithSender:(id)sender;	//	IMPLEMENTED

- (void) presentImagePickerController:(IRImagePickerController *)controller sender:(id)sender;
- (void) presentCameraCapturePickerController:(IRImagePickerController *)controller sender:(id)sender;

- (void) dismissImagePickerController:(IRImagePickerController *)controller;
- (void) dismissCameraCapturePickerController:(IRImagePickerController *)controller;

- (void) handleIncomingSelectedAssetURI:(NSURL *)aFileURL representedAsset:(ALAsset *)photoLibraryAsset;

@end
