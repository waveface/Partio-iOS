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

#import <objc/runtime.h>
#import "WACompositionViewController+SubclassEyesOnly.h"
#import "AGImagePickerController.h"

NSString * const WACompositionImageInsertionUsesCamera = @"WACompositionImageInsertionUsesCamera";
NSString * const WACompositionImageInsertionAnimatePresentation = @"WACompositionImageInsertionAnimatePresentation";
NSString * const WACompositionImageInsertionCancellationTriggersSessionTermination = @"WACompositionImageInsertionCancellationTriggersSessionTermination";

NSString * const kDismissesSelfIfCameraCancelled = @"-[WACompositionViewController(ImageHandling) dismissesSelfIfCameraCancelled]";

@interface WACompositionViewController (ImageHandling_Private)

- (IRAction *) newPresentImagePickerControllerActionAnimated:(BOOL)animate sender:(id)sender;
- (IRAction *) newPresentCameraCaptureControllerActionAnimated:(BOOL)animate sender:(id)sender;

@end


@implementation WACompositionViewController (ImageHandling)

- (IRAction *) newPresentImagePickerControllerActionAnimated:(BOOL)animate sender:(id)sender {

	__weak WACompositionViewController *wSelf = self;
	
	AGImagePickerController *imagePickerController = [[AGImagePickerController alloc] initWithFailureBlock:^(NSError *error) {
		NSLog(@"Failed. Error: %@", error);
		if( error == nil ) {
			[wSelf dismissModalViewControllerAnimated:YES];
		}
	} andSuccessBlock:^(NSArray *info) {
		NSLog(@"Info: %@", info);
		[wSelf handleSelectionWithArray:info];
		[wSelf dismissModalViewControllerAnimated:YES];

	}];
	
	return [IRAction actionWithTitle:NSLocalizedString(@"ACTION_INSERT_PHOTO_FROM_LIBRARY", @"Button title for showing an image picker") block: ^ {
	
		[wSelf presentModalViewController:imagePickerController animated:YES];
	
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

- (void) handleSelectionWithArray: (NSArray *)selectedAssets {
	for (ALAsset *asset in selectedAssets) {
		[self handleIncomingSelectedAssetURI:nil representedAsset:asset];
	}
}

- (void) handleIncomingSelectedAssetURI:(NSURL *)selectedAssetURI representedAsset:(ALAsset *)representedAsset {
	
	if(representedAsset){
		NSLog(@"URI: %@", [[representedAsset defaultRepresentation] url]);
	}
	
	if (selectedAssetURI || representedAsset) {

		WAArticle *capturedArticle = self.article;
		WAFile *stitchedFile = (WAFile *)[WAFile objectInsertingIntoContext:self.managedObjectContext withRemoteDictionary:[NSDictionary dictionary]];
		
		NSCParameterAssert(capturedArticle);
		
		NSError *error = nil;
		if (![stitchedFile.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObjects:stitchedFile, capturedArticle, nil] error:&error])
			NSLog(@"Error obtaining permanent object ID: %@", error);

		[capturedArticle willChangeValueForKey:@"files"];
		[[capturedArticle mutableOrderedSetValueForKey:@"files"] addObject:stitchedFile];
		[capturedArticle didChangeValueForKey:@"files"];
		
		NSURL *finalFileURL = nil;
		
		if (selectedAssetURI) {
			finalFileURL = [[WADataStore defaultStore] persistentFileURLForFileAtURL:selectedAssetURI];
			NSCParameterAssert([finalFileURL pathExtension]);
		}
		
		if (representedAsset) {
			UIImageOrientation orientation = UIImageOrientationUp;
			NSNumber* orientationValue = [representedAsset valueForProperty:@"ALAssetPropertyOrientation"];
			if (orientationValue != nil) {
				orientation = [orientationValue intValue];
			}
			
			CGFloat scale = 1.0;
			UIImage *image = [UIImage imageWithCGImage:[[representedAsset defaultRepresentation] fullResolutionImage] scale:scale orientation:orientation];
			
			NSData *fullResolutionData = UIImageJPEGRepresentation(image, 1.0);
			
			finalFileURL = [[WADataStore defaultStore]
											persistentFileURLForData:fullResolutionData 
											extension:[[representedAsset defaultRepresentation] UTI]];
			image = nil;
			fullResolutionData = nil;
		}
					
		stitchedFile.resourceType = (NSString *)kUTTypeImage;
		stitchedFile.resourceFilePath = [finalFileURL path];
		
	} else {
		
		//	If told to dismiss self, dismiss here if self has no changess
		
		BOOL shouldDismissSelfOnCameraCancellation = [objc_getAssociatedObject(self, &kDismissesSelfIfCameraCancelled) isEqual:(id)kCFBooleanTrue];
		
		if (shouldDismissSelfOnCameraCancellation) {
			
			if (![self.article hasMeaningfulContent]) {
 
				self.completionBlock(nil);

			}
			
		}
		
	}
	
	objc_setAssociatedObject(self, &kDismissesSelfIfCameraCancelled, nil, OBJC_ASSOCIATION_ASSIGN);

}

- (BOOL) shouldDismissSelfOnCameraCancellation {
	
	return [objc_getAssociatedObject(self, &kDismissesSelfIfCameraCancelled) isEqual:(id)kCFBooleanTrue];

}

- (void) handleImageAttachmentInsertionRequestWithSender:(id)sender {

	[self handleImageAttachmentInsertionRequestWithOptions:nil sender:sender];

}

- (void) handleImageAttachmentInsertionRequestWithOptions:(NSDictionary *)options sender:(id)sender {
		
	NSMutableArray *availableActions = [NSMutableArray array];
	
	BOOL usesCamera = [[options objectForKey:WACompositionImageInsertionUsesCamera] isEqual:(id)kCFBooleanTrue];
	BOOL animate = ![[options objectForKey:WACompositionImageInsertionAnimatePresentation] isEqual:(id)kCFBooleanFalse];
	BOOL dismissesSelfIfCameraCancelled = [[options objectForKey:WACompositionImageInsertionCancellationTriggersSessionTermination] isEqual:(id)kCFBooleanTrue];
	
	objc_setAssociatedObject(self, &kDismissesSelfIfCameraCancelled, (dismissesSelfIfCameraCancelled ? (id)kCFBooleanTrue : (id)kCFBooleanFalse), OBJC_ASSOCIATION_ASSIGN);
	
	IRAction *photoPickerAction = [self newPresentImagePickerControllerActionAnimated:animate sender:sender];
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
