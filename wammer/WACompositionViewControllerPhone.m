//
//  WACompositionViewControllerPhone.m
//  wammer
//
//  Created by Evadne Wu on 2/20/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WACompositionViewControllerPhone.h"
#import "UIKit+IRAdditions.h"

#import "WAPreviewInspectionViewController.h"
#import "WADataStore.h"

@interface WACompositionViewControllerPhone () <WAPreviewInspectionViewControllerDelegate>

@property (nonatomic, readwrite, retain) IRActionSheetController *actionSheetController;

@end

@implementation WACompositionViewControllerPhone
@synthesize actionSheetController;

- (void) viewDidUnload {

	self.actionSheetController = nil;
	
	[super viewDidUnload];

}

- (void) dealloc {

	[actionSheetController release];
	[super dealloc];

}

- (void) presentCameraCapturePickerController:(IRImagePickerController *)controller sender:(id)sender {

	[super presentCameraCapturePickerController:controller sender:sender];

}

- (void) handlePreviewBadgeTap:(id)sender {

	self.actionSheetController = nil;
	
	WAPreviewInspectionViewController *previewVC = [WAPreviewInspectionViewController controllerWithPreview:[[self.previewBadge.preview objectID] URIRepresentation]];
	previewVC.delegate = self;
	
	UINavigationController *navC = [previewVC wrappingNavController];
	[self presentModalViewController:navC animated:YES];

}

- (void) previewInspectionViewControllerDidFinish:(WAPreviewInspectionViewController *)inspector {

	[inspector dismissModalViewControllerAnimated:YES];

}

- (void) previewInspectionViewControllerDidRemove:(WAPreviewInspectionViewController *)inspector {

	//	[inspector dismissModalViewControllerAnimated:YES];
	
	__block __typeof__(self) nrSelf = self;
	
	if (self.actionSheetController.managedActionSheet.visible)
		return;
	
	if (!self.actionSheetController) {
	
		WAPreview *removedPreview = self.previewBadge.preview;
		NSParameterAssert([[inspector.preview objectID] isEqual:[removedPreview objectID]]);
			
		IRAction *discardAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_DISCARD", nil) block:^{
		
			[removedPreview.article removePreviewsObject:removedPreview];
			[inspector dismissModalViewControllerAnimated:YES];

			nrSelf.actionSheetController = nil;
			
		}];
		
		self.actionSheetController = [IRActionSheetController actionSheetControllerWithTitle:nil cancelAction:nil destructiveAction:discardAction otherActions:nil];
		
	}

	[self.actionSheetController.managedActionSheet showInView:inspector.view];
	
}

@end
