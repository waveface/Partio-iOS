//
//  WACompositionViewController+ImageHandling.m
//  wammer
//
//  Created by Evadne Wu on 2/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WACompositionViewController+ImageHandling.h"
#import "UIKit+IRAdditions.h"
#import "AssetsLibrary+IRAdditions.h"
#import "WADataStore.h"

NSString * const WACompositionImageInsertionUsesCamera = @"WACompositionImageInsertionUsesCamera";
NSString * const WACompositionImageInsertionAnimatePresentation = @"WACompositionImageInsertionAnimatePresentation";

@interface WACompositionViewController (ImageHandling_Private)

- (IRAction *) newPresentImagePickerControllerActionAnimated:(BOOL)animate sender:(id)sender;
- (IRAction *) newPresentCameraCaptureControllerActionAnimated:(BOOL)animate sender:(id)sender;

@end


@implementation WACompositionViewController (ImageHandling)

- (IRAction *) newPresentImagePickerControllerActionAnimated:(BOOL)animate sender:(id)sender {

	__weak WACompositionViewController *wSelf = self;
	__weak id wSender = sender;
	
	return [IRAction actionWithTitle:NSLocalizedString(@"ACTION_INSERT_PHOTO_FROM_LIBRARY", @"Button title for showing an image picker") block: ^ {
	
		[wSelf presentImagePickerController:[wSelf newImagePickerController] sender:wSender animated:animate];
	
	}];

}

- (IRImagePickerController *) newImagePickerController {

	__weak WACompositionViewController *wSelf = self;
	
	__block IRImagePickerController *nrImagePickerController = [IRImagePickerController photoLibraryPickerWithCompletionBlock:^(NSURL *selectedAssetURI, ALAsset *representedAsset) {
		
		[wSelf handleIncomingSelectedAssetURI:selectedAssetURI representedAsset:representedAsset];
		[wSelf dismissImagePickerController:nrImagePickerController animated:YES];
		
		nrImagePickerController = nil;
		
	}];
	
	nrImagePickerController.usesAssetsLibrary = NO;
	
	return nrImagePickerController;

}

- (void) presentImagePickerController:(IRImagePickerController *)controller sender:(id)sender animated:(BOOL)animated {

	__block UIViewController * (^topNonModalVC)(UIViewController *) = [^ (UIViewController *aVC) {
		
		if (aVC.modalViewController)
			return topNonModalVC(aVC.modalViewController);
		
		return aVC;
		
	} copy];
	
	[topNonModalVC(self) presentModalViewController:[self newImagePickerController] animated:animated];
	
	topNonModalVC = nil;

}

- (void) dismissImagePickerController:(IRImagePickerController *)controller animated:(BOOL)animated {

	[controller dismissModalViewControllerAnimated:animated];

}

- (IRAction *) newPresentCameraCaptureControllerActionAnimated:(BOOL)animate sender:(id)sender {

	if (![IRImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear])
		return nil;
	
	__weak WACompositionViewController *wSelf = self;
	__weak id wSender = sender;
	
	return [IRAction actionWithTitle:NSLocalizedString(@"ACTION_TAKE_PHOTO_WITH_CAMERA", @"Button title for showing a camera capture controller") block: ^ {
	
		[wSelf presentCameraCapturePickerController:[wSelf newCameraCapturePickerController] sender:wSender animated:animate];
	
	}];

}

- (IRImagePickerController *) newCameraCapturePickerController {

	__weak WACompositionViewController *wSelf = self;
	
	__block IRImagePickerController *nrPickerController = [IRImagePickerController cameraImageCapturePickerWithCompletionBlock:^(NSURL *selectedAssetURI, ALAsset *representedAsset) {
		
		[wSelf handleIncomingSelectedAssetURI:selectedAssetURI representedAsset:representedAsset];
		[wSelf dismissCameraCapturePickerController:nrPickerController animated:YES];
		
		nrPickerController = nil;
		
	}];
	
	nrPickerController.usesAssetsLibrary = NO;
	nrPickerController.savesCameraImageCapturesToSavedPhotos = YES;
	
	return nrPickerController;

}

- (void) presentCameraCapturePickerController:(IRImagePickerController *)controller sender:(id)sender animated:(BOOL)animated {

	__block UIViewController * (^topNonModalVC)(UIViewController *) = [^ (UIViewController *aVC) {
		
		if (aVC.modalViewController)
			return topNonModalVC(aVC.modalViewController);
		
		return aVC;
		
	} copy];
	
	[topNonModalVC(self) presentModalViewController:controller animated:animated];
	
	topNonModalVC = nil;

}

- (void) dismissCameraCapturePickerController:(IRImagePickerController *)controller animated:(BOOL)animated {

	[controller dismissModalViewControllerAnimated:animated];

}

- (void) handleIncomingSelectedAssetURI:(NSURL *)selectedAssetURI representedAsset:(ALAsset *)representedAsset {
	
	if (selectedAssetURI || representedAsset) {

		WAArticle *capturedArticle = self.article;
		WAFile *stitchedFile = (WAFile *)[WAFile objectInsertingIntoContext:self.managedObjectContext withRemoteDictionary:[NSDictionary dictionary]];
		
		NSError *error = nil;
		if (![stitchedFile.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObjects:stitchedFile, nil] error:&error])
			NSLog(@"Error obtaining permanent object ID: %@", error);

		[capturedArticle addFilesObject:stitchedFile];
		
		NSURL *finalFileURL = nil;
		
		if (selectedAssetURI)
			finalFileURL = [[WADataStore defaultStore] persistentFileURLForFileAtURL:selectedAssetURI];
		
		if (!finalFileURL)
		if (!selectedAssetURI && representedAsset) {
		
			UIImage *fullImage = [[representedAsset defaultRepresentation] irImage];
			NSData *fullImageData = UIImagePNGRepresentation(fullImage);
			
			finalFileURL = [[WADataStore defaultStore] persistentFileURLForData:fullImageData extension:@"png"];
		
		}
					
		stitchedFile.resourceType = (NSString *)kUTTypeImage;
		stitchedFile.resourceFilePath = [finalFileURL path];
		
	}

}

- (void) handleImageAttachmentInsertionRequestWithSender:(id)sender {

	[self handleImageAttachmentInsertionRequestWithOptions:nil sender:sender];

}

- (void) handleImageAttachmentInsertionRequestWithOptions:(NSDictionary *)options sender:(id)sender {
		
	NSMutableArray *availableActions = [NSMutableArray array];
	
	BOOL usesCamera = [[options objectForKey:WACompositionImageInsertionUsesCamera] isEqual:(id)kCFBooleanTrue];
	BOOL animate = ![[options objectForKey:WACompositionImageInsertionAnimatePresentation] isEqual:(id)kCFBooleanFalse];
	
	IRAction *photoPickerAction = [self newPresentCameraCaptureControllerActionAnimated:animate sender:sender];
	IRAction *cameraAction = [self newPresentCameraCaptureControllerActionAnimated:animate sender:sender];
	
	[availableActions addObject:photoPickerAction];
	
	if (cameraAction)
		[availableActions addObject:cameraAction];
	
	if (usesCamera && cameraAction) {
	
		[cameraAction invoke];
	
	} else if (usesCamera && photoPickerAction) {
	
		[photoPickerAction invoke];
	
	} else if ([availableActions count] == 1) {
		
		//	With only one action we don’t even need to show the action sheet
		
		dispatch_async(dispatch_get_main_queue(), ^ {
			[(IRAction *)[availableActions objectAtIndex:0] invoke];
		});
		
	} else {
	
		IRActionSheetController *controller = [IRActionSheetController actionSheetControllerWithTitle:nil cancelAction:nil destructiveAction:nil otherActions:availableActions];
		IRActionSheet *actionSheet = (IRActionSheet *)[controller singleUseActionSheet];
		
		if ([sender isKindOfClass:[UIView class]]) {
			
			[actionSheet showFromRect:((UIView *)sender).bounds inView:((UIView *)sender) animated:YES];
			
		} else if ([sender isKindOfClass:[UIBarButtonItem class]]) {
			
			[actionSheet showFromBarButtonItem:((UIBarButtonItem *)sender) animated:YES];
			
		} else {
			
			[NSException raise:NSInternalInconsistencyException format:@"Sender %@ is neither a view or a bar button item.  Don’t know what to do.", sender];
		
		}
		
	}
	
}

@end
