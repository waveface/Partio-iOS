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

enum {
	WAThumbnailMakeOptionExtraSmall = 1,
	WAThumbnailMakeOptionSmall = 1 << 1,
	WAThumbnailMakeOptionMedium = 1 << 2,
	WAThumbnailMakeOptionLarge = 1 << 3
}; typedef NSInteger WAThumbnailMakeOptions;


@interface WACompositionViewController (ImageHandling)

- (IRImagePickerController *) newCameraCapturePickerController;

- (void) handleImageAttachmentInsertionRequestWithSender:(id)sender;
- (void) handleImageAttachmentInsertionRequestWithOptions:(NSDictionary *)options sender:(id)sender;

- (void) presentImagePickerController:(UIViewController *)controller sender:(id)sender animated:(BOOL)animated;
- (void) dismissImagePickerController:(UIViewController *)controller animated:(BOOL)animated;

- (void) presentCameraCapturePickerController:(UIViewController *)controller sender:(id)sender animated:(BOOL)animated;
- (void) dismissCameraCapturePickerController:(UIViewController *)controller animated:(BOOL)animated;

/** Generate thumbnails of a WAFile entity with the given asset and options.
 *
 *	@param file The WAFile entity to be associated with generated thumbnails.
 *	@param representedAsset The asset of file from camera roll.
 *	@param options The options specify what kind of thumbnails to be generated.
 */
- (void) makeAssociatedImagesOfFile:(WAFile *)file withRepresentedAsset:(ALAsset *)representedAsset options:(WAThumbnailMakeOptions)options;

/** Handle incoming assets from camera roll.
 *
 *	@param representedAsset The asset of file from camera roll.
 *	@param options The options specify what kind of thumbnails to be generated, will be passed to makeAssociatedImagesOfFile:withRepresentedAsset:options:.
 */
- (void) handleIncomingSelectedAsset:(ALAsset *)representedAsset options:(WAThumbnailMakeOptions)options;

- (BOOL) shouldDismissSelfOnCameraCancellation;

- (void) handleSelectionWithArray: (NSArray *)selectedAssets;

@end

extern NSString * const WACompositionImageInsertionUsesCamera;
extern NSString * const WACompositionImageInsertionAnimatePresentation;
extern NSString * const WACompositionImageInsertionCancellationTriggersSessionTermination;