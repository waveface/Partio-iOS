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

#import "WAArticleAttachmentActivityView.h"
#import "IRTextAttributor.h"

#import "Foundation+IRAdditions.h"

#import "WAAttachedMediaListViewController.h"
#import "WANavigationController.h"

#import "IRLifetimeHelper.h"


@interface WACompositionViewController (PhoneSubclassKnowledge) <IRTextAttributorDelegate>

@end


@interface WACompositionViewControllerPhone () <WAPreviewInspectionViewControllerDelegate>

@property (nonatomic, readwrite, retain) IRActionSheetController *actionSheetController;
@property (nonatomic, readwrite, retain) WAArticleAttachmentActivityView *articleAttachmentActivityView;

- (WAAttachedMediaListViewController *) newMediaListViewController NS_RETURNS_RETAINED;
- (void) presentMediaListViewController:(WAAttachedMediaListViewController *)controller sender:(id)sender animated:(BOOL)animated;
- (void) dismissMediaListViewController:(WAAttachedMediaListViewController *)controller animated:(BOOL)animated;

- (void) handleArticleAttachmentActivityViewTap:(WAArticleAttachmentActivityView *)view;

- (void) updateArticleAttachmentActivityView;

@property (nonatomic, readwrite, copy) void (^onDismissImagePickerControllerAnimated)(IRImagePickerController *controller, BOOL animated, BOOL *overrideDefault);
@property (nonatomic, readwrite, copy) void (^onDismissCameraCaptureControllerAnimated)(IRImagePickerController *controller, BOOL animated, BOOL *overrideDefault);

@end

@implementation WACompositionViewControllerPhone
@synthesize toolbar, actionSheetController, articleAttachmentActivityView;
@synthesize onDismissImagePickerControllerAnimated, onDismissCameraCaptureControllerAnimated;

- (id) init {

	return [self initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	self.contentTextView.backgroundColor = nil;
	self.contentTextView.contentInset = (UIEdgeInsets){ 4, 0, 64, 0 };
	self.contentTextView.font = [UIFont systemFontOfSize:18.0f];
		
	self.toolbar.items = [NSArray arrayWithObjects:
		[IRBarButtonItem itemWithCustomView:self.articleAttachmentActivityView],
	nil];
	
	self.toolbar.backgroundColor = nil;
	self.toolbar.opaque = NO;
	
}

- (void) viewDidUnload {

	self.actionSheetController = nil;
	self.toolbar = nil;
	
	[super viewDidUnload];

}

- (void) dealloc {

	[actionSheetController release];
	[toolbar release];
	[articleAttachmentActivityView release];
	
	[onDismissImagePickerControllerAnimated release];
	[onDismissCameraCaptureControllerAnimated release];
	
	[super dealloc];

}

- (void) viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];
	
	[self.contentTextView becomeFirstResponder];

}

- (void) adjustContainerViewWithInterfaceBounds:(CGRect)newBounds {

	if (![self isViewLoaded])
		return;
		
	[super adjustContainerViewWithInterfaceBounds:newBounds];
	
	if (CGRectEqualToRect(self.view.bounds, [self.view convertRect:self.containerView.bounds fromView:self.containerView])) {
	
		self.contentTextView.scrollIndicatorInsets = (UIEdgeInsets){ 0, 0, 6, 0};
	
	} else {
	
		self.contentTextView.scrollIndicatorInsets = UIEdgeInsetsZero;
	
	}

}

- (WAArticleAttachmentActivityView *) articleAttachmentActivityView {

	if (articleAttachmentActivityView)
		return articleAttachmentActivityView;
	
	__block __typeof__(self) nrSelf = self;
	__block __typeof__(articleAttachmentActivityView) nrArticleAttachmentActivityView = [[WAArticleAttachmentActivityView alloc] initWithFrame:(CGRect){ CGPointZero, (CGSize){ 96, 32 }}];
	
	nrArticleAttachmentActivityView.onTap = ^ {
	
		[nrSelf handleArticleAttachmentActivityViewTap:nrArticleAttachmentActivityView];
	
	};
	
	articleAttachmentActivityView = nrArticleAttachmentActivityView;
	
	[self updateArticleAttachmentActivityView];
	
	return articleAttachmentActivityView;

}

- (void) updateArticleAttachmentActivityView {

	if (![self isViewLoaded])
		return;

	self.articleAttachmentActivityView.style = !![self.textAttributor.queue.operations count] ? WAArticleAttachmentActivityViewSpinnerStyle :
		[self.article.previews count] ? WAArticleAttachmentActivityViewLinkStyle :
		[self.article.files count] ? WAArticleAttachmentActivityViewAttachmentsStyle :
		WAArticleAttachmentActivityViewDefaultStyle;
	
	[self.articleAttachmentActivityView setTitle:[NSString stringWithFormat:NSLocalizedString(@"NUMBER_OF_PHOTOS",@"attachment activity view"), [self.article.files count]] forStyle:WAArticleAttachmentActivityViewAttachmentsStyle];
	if ([self.article.files count]==0) 
		[self.articleAttachmentActivityView setTitle:NSLocalizedString(@"ACTION_ADD",@"attachment activity view") forStyle:WAArticleAttachmentActivityViewAttachmentsStyle];
		
	[self.articleAttachmentActivityView setTitle:NSLocalizedString(@"WEB_PREVIEW",@"attachment activity view") forStyle:WAArticleAttachmentActivityViewLinkStyle];

}

- (IRTextAttributor *) textAttributor {

	__block IRTextAttributor *returnedAttributor = [super textAttributor];
	
	if (objc_getAssociatedObject(returnedAttributor, _cmd))
		return returnedAttributor;
	
	__block __typeof__(self) nrSelf = self;
	__block id observer = [returnedAttributor.queue irAddObserverBlock:^(id inOldValue, id inNewValue, NSKeyValueChange changeKind) {
	
		[nrSelf retain];
	
		dispatch_async(dispatch_get_main_queue(), ^ {

			[nrSelf updateArticleAttachmentActivityView];
			[nrSelf autorelease];
		
		});
		
	} forKeyPath:@"operations" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
	
	[returnedAttributor irPerformOnDeallocation:^{
	
	 [returnedAttributor irRemoveObservingsHelper:observer];
		
	}];

	NSCParameterAssert(!objc_getAssociatedObject(returnedAttributor, _cmd));
	objc_setAssociatedObject(returnedAttributor, _cmd, (id)kCFBooleanTrue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	NSCParameterAssert(objc_getAssociatedObject(returnedAttributor, _cmd));
	
	return returnedAttributor;

}

- (void) textAttributor:(IRTextAttributor *)attributor willUpdateAttributedString:(NSAttributedString *)attributedString withToken:(NSString *)aToken range:(NSRange)tokenRange attribute:(id)newAttribute {

	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		[super textAttributor:attributor willUpdateAttributedString:attributedString withToken:aToken range:tokenRange attribute:newAttribute];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		[self updateArticleAttachmentActivityView];

	});
	
}

- (void) textAttributor:(IRTextAttributor *)attributor didUpdateAttributedString:(NSAttributedString *)attributedString withToken:(NSString *)aToken range:(NSRange)tokenRange attribute:(id)newAttribute {

	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		[super textAttributor:attributor didUpdateAttributedString:attributedString withToken:aToken range:tokenRange attribute:newAttribute];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		[self updateArticleAttachmentActivityView];

	});

}

- (void) handleCurrentArticleFilesChangedFrom:(id)fromValue to:(id)toValue changeKind:(NSKeyValueChange)changeKind {

	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		[super handleCurrentArticleFilesChangedFrom:fromValue to:toValue changeKind:changeKind];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		[self updateArticleAttachmentActivityView];

	});

}

- (void) handleCurrentArticlePreviewsChangedFrom:(id)fromValue to:(id)toValue changeKind:(NSKeyValueChange)changeKind {

	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		[super handleCurrentArticlePreviewsChangedFrom:fromValue to:toValue changeKind:changeKind];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		[self updateArticleAttachmentActivityView];

	});

}

- (void) handleArticleAttachmentActivityViewTap:(WAArticleAttachmentActivityView *)view {

	switch (view.style) {
	
		case WAArticleAttachmentActivityViewAttachmentsStyle: {
		
			if ([self.article.files count]) {
			
				[self presentMediaListViewController:[[self newMediaListViewController] autorelease] sender:view animated:YES];
			
			} else {
			
				[self handleImageAttachmentInsertionRequestWithSender:view];
				
				__block __typeof__(self) nrSelf = self;
				
				NSArray *capturedFiles = [[self.article.fileOrder copy] autorelease];
				BOOL (^filesChanged)(void) = ^ {
					return (BOOL)![nrSelf.article.fileOrder isEqual:capturedFiles];
				};
				
				CALayer *crossfadeLayer = nrSelf.view.window.layer;
				
				void (^crossfade)(void(^)(void)) = ^ (void(^aBlock)(void)) {
				
					CATransition *transition = [CATransition animation];
					transition.type = kCATransitionFade;
					transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
					transition.duration = 0.3;
					transition.removedOnCompletion = YES;
					transition.fillMode = kCAFillModeForwards;
					
					[CATransaction begin];
					[CATransaction setDisableActions:YES];
					
					aBlock();
					
					[crossfadeLayer addAnimation:transition forKey:kCATransition];
					
					[CATransaction commit];
					
				};
				
				
				self.onDismissCameraCaptureControllerAnimated = ^ (IRImagePickerController *controller, BOOL animated, BOOL *overrideDefault) {
				
					[[nrSelf.onDismissCameraCaptureControllerAnimated retain] autorelease];
					
					nrSelf.onDismissCameraCaptureControllerAnimated = nil;
					
					if (!filesChanged())
						return;
					
					*overrideDefault = YES;
					
					crossfade(^ {
					
						[nrSelf dismissCameraCapturePickerController:controller animated:NO];
						[nrSelf presentMediaListViewController:[[self newMediaListViewController] autorelease] sender:nil animated:NO];
					
					});
									
				};
				
				self.onDismissImagePickerControllerAnimated = ^ (IRImagePickerController *controller, BOOL animated, BOOL *overrideDefault) {
				
					[[nrSelf.onDismissImagePickerControllerAnimated retain] autorelease];
					
					nrSelf.onDismissImagePickerControllerAnimated = nil;

					if (!filesChanged())
						return;
					
					*overrideDefault = YES;
				
					crossfade(^ {

						[nrSelf dismissImagePickerController:controller animated:NO];
						[nrSelf presentMediaListViewController:[[self newMediaListViewController] autorelease] sender:nil animated:NO];
					
					});
				
				};
				
			}
										 
			break;
			
		}
	
		case WAArticleAttachmentActivityViewLinkStyle: {
			
			NSParameterAssert([self.article.previews count]);
			
			WAPreview *inspectedPreview = [self.article.previews anyObject];
			
			TFLog(@"Inspecting preview %@", inspectedPreview);
			[self inspectPreview:inspectedPreview];			
			
			break;
			
		}

		case WAArticleAttachmentActivityViewSpinnerStyle: {
			break;
		}

	}

}

- (WAAttachedMediaListViewController *) newMediaListViewController {

	__block __typeof__(self) nrSelf = self;
	__block WAAttachedMediaListViewController *mediaList = [[WAAttachedMediaListViewController alloc] initWithArticleURI:[self.article.objectID URIRepresentation] usingContext:self.managedObjectContext completion: ^ {
	
		[nrSelf dismissMediaListViewController:mediaList animated:YES];
		
	}];
	
	mediaList.navigationItem.rightBarButtonItem = [IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemAdd wiredAction:^(IRBarButtonItem *senderItem) {
	
		[nrSelf handleImageAttachmentInsertionRequestWithSender:senderItem];
		
	}];
	
	mediaList.onViewDidLoad = ^ {
		[mediaList.tableView setEditing:YES animated:NO];
	};
	
	if ([mediaList isViewLoaded])
		mediaList.onViewDidLoad();
	
	return mediaList;

}

- (void) presentMediaListViewController:(WAAttachedMediaListViewController *)controller sender:(id)sender animated:(BOOL)animated {

	WANavigationController *navC = [[[WANavigationController alloc] initWithRootViewController:[[self newMediaListViewController] autorelease]] autorelease];
	
	[self presentModalViewController:navC animated:animated];

}

- (void) dismissMediaListViewController:(WAAttachedMediaListViewController *)controller animated:(BOOL)animated {

	[controller dismissModalViewControllerAnimated:animated];

}

- (void) dismissImagePickerController:(IRImagePickerController *)controller animated:(BOOL)animated {

	BOOL shouldOverride = NO;
	
	if (self.onDismissImagePickerControllerAnimated)
		self.onDismissImagePickerControllerAnimated(controller, animated, &shouldOverride);
	
	if (!shouldOverride)
		[super dismissImagePickerController:controller animated:animated];

}

- (void) dismissCameraCapturePickerController:(IRImagePickerController *)controller animated:(BOOL)animated {

	BOOL shouldOverride = NO;
	
	if (self.onDismissCameraCaptureControllerAnimated)
		self.onDismissCameraCaptureControllerAnimated(controller, animated, &shouldOverride);
	
	if (!shouldOverride)
		[super dismissCameraCapturePickerController:controller animated:animated];

}

- (void) inspectPreview:(WAPreview *)aPreview {
	
	NSCParameterAssert(aPreview.managedObjectContext == self.managedObjectContext);
	
	NSError *savingError = nil;
	if (![self.managedObjectContext save:&savingError])
		NSLog(@"Error saving preview: %@", savingError);

	self.actionSheetController = nil;
	
	WAPreviewInspectionViewController *previewVC = [WAPreviewInspectionViewController controllerWithPreview:[[aPreview objectID] URIRepresentation]];
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
	
		WAPreview *removedPreview = [self.article.previews anyObject];
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
