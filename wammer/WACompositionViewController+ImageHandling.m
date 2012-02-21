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

@implementation WACompositionViewController (ImageHandling)

- (IRAction *) newPresentImagePickerControllerActionWithSender:(id)sender {

	__block __typeof__(self) nrSelf = self;
	__block __typeof__(self) nrSender = sender;
	
	return [[IRAction actionWithTitle:@"Photo Library" block: ^ {
	
		[nrSelf presentImagePickerController:[[nrSelf newImagePickerController] autorelease] sender:nrSender];
	
	}] retain];

}

- (IRImagePickerController *) newImagePickerController {

	__block __typeof__(self) nrSelf = self;
	__block IRImagePickerController *nrImagePickerController = [IRImagePickerController photoLibraryPickerWithCompletionBlock:^(NSURL *selectedAssetURI, ALAsset *representedAsset) {
		
		[nrSelf handleIncomingSelectedAssetURI:selectedAssetURI representedAsset:representedAsset];
		[nrSelf dismissImagePickerController:nrImagePickerController];
		
	}];
	
	nrImagePickerController.usesAssetsLibrary = NO;
	
	return [nrImagePickerController retain];

}

- (void) presentImagePickerController:(IRImagePickerController *)controller sender:(id)sender {

	__block UIViewController * (^topNonModalVC)(UIViewController *) = ^ (UIViewController *aVC) {
		
		if (aVC.modalViewController)
			return topNonModalVC(aVC.modalViewController);
		
		return aVC;
		
	};
	
	[topNonModalVC(self) presentModalViewController:[[self newImagePickerController] autorelease] animated:YES];

}

- (void) dismissImagePickerController:(IRImagePickerController *)controller {

	[controller dismissModalViewControllerAnimated:YES];

}

- (IRAction *) newPresentCameraCaptureControllerActionWithSender:(id)sender {

	__block __typeof__(self) nrSelf = self;
	__block __typeof__(self) nrSender = sender;
		
	return [[IRAction actionWithTitle:@"Take Photo" block: ^ {
	
		[nrSelf presentCameraCapturePickerController:[[nrSelf newCameraCapturePickerController] autorelease] sender:nrSender];
	
	}] retain];

}

- (IRImagePickerController *) newCameraCapturePickerController {

	__block __typeof__(self) nrSelf = self;
	
	__block IRImagePickerController *nrPickerController = [IRImagePickerController cameraImageCapturePickerWithCompletionBlock:^(NSURL *selectedAssetURI, ALAsset *representedAsset) {
		
		[nrSelf handleIncomingSelectedAssetURI:selectedAssetURI representedAsset:representedAsset];
		[nrSelf dismissCameraCapturePickerController:nrPickerController];
		
	}];
	
	nrPickerController.usesAssetsLibrary = NO;
	nrPickerController.savesCameraImageCapturesToSavedPhotos = YES;
	
	return [nrPickerController retain];

}

- (void) presentCameraCapturePickerController:(IRImagePickerController *)controller sender:(id)sender {
		
	__block UIViewController * (^topNonModalVC)(UIViewController *) = ^ (UIViewController *aVC) {
		
		if (aVC.modalViewController)
			return topNonModalVC(aVC.modalViewController);
		
		return aVC;
		
	};
	
	[topNonModalVC(self) presentModalViewController:controller animated:YES];

}

- (void) dismissCameraCapturePickerController:(IRImagePickerController *)controller {

	[controller dismissModalViewControllerAnimated:YES];

}

- (void) handleIncomingSelectedAssetURI:(NSURL *)selectedAssetURI representedAsset:(ALAsset *)representedAsset {
	
	if (selectedAssetURI || representedAsset) {

		WAArticle *capturedArticle = self.article;
		WAFile *stitchedFile = (WAFile *)[WAFile objectInsertingIntoContext:self.managedObjectContext withRemoteDictionary:[NSDictionary dictionary]];
		stitchedFile.article = capturedArticle;
		
		NSURL *finalFileURL = nil;
		
		if (selectedAssetURI)
			finalFileURL = [[WADataStore defaultStore] persistentFileURLForFileAtURL:selectedAssetURI];
		
		if (!finalFileURL)
		if (!selectedAssetURI && representedAsset) {
		
			UIImage *fullImage = [[representedAsset defaultRepresentation] irImage];
			NSData *fullImageData = UIImagePNGRepresentation(fullImage);
			
			finalFileURL = [[WADataStore defaultStore] persistentFileURLForData:fullImageData extension:@"png"];
		
		}
			
		[stitchedFile.article willChangeValueForKey:@"fileOrder"];
		
		stitchedFile.resourceType = (NSString *)kUTTypeImage;
		stitchedFile.resourceFilePath = [finalFileURL path];
		
		[stitchedFile.article didChangeValueForKey:@"fileOrder"];
		
	}

}

@end
