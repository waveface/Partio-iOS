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

@interface WACompositionViewControllerPhone () <WAPreviewInspectionViewControllerDelegate>

@property (nonatomic, readwrite, retain) IRActionSheetController *actionSheetController;
@property (nonatomic, readwrite, retain) WAArticleAttachmentActivityView *articleAttachmentActivityView;

- (void) handleArticleAttachmentActivityViewTap:(WAArticleAttachmentActivityView *)view;

- (void) updateArticleAttachmentActivityView;

@end

@implementation WACompositionViewControllerPhone
@synthesize toolbar, actionSheetController, articleAttachmentActivityView;

- (id) init {

	return [self initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	self.contentTextView.backgroundColor = nil;
	self.contentTextView.contentInset = (UIEdgeInsets){ 4, 0, 64, 0 };
	self.contentTextView.scrollIndicatorInsets = (UIEdgeInsets){ 0, 0, 44, 0 };
	self.contentTextView.font = [UIFont systemFontOfSize:18.0f];
		
	self.toolbar.items = [NSArray arrayWithObjects:
		[IRBarButtonItem itemWithCustomView:self.articleAttachmentActivityView],
	nil];
	
	self.toolbar.backgroundColor = nil;
	self.toolbar.opaque = NO;
	
	self.containerView.backgroundColor = nil;
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WACompositionBackgroundPattern"]];
	
	UIImage *bottomCapImage = [[UIImage imageNamed:@"WACompositionBackgroundBottomCap"] stretchableImageWithLeftCapWidth:16 topCapHeight:0];	
	UIImageView *bottomCapView = [[[UIImageView alloc] initWithImage:bottomCapImage] autorelease];
	bottomCapView.frame = IRGravitize(self.view.bounds, (CGSize){ CGRectGetWidth(self.view.bounds), bottomCapImage.size.height }, kCAGravityBottom);
	bottomCapView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
	
	[self.view addSubview:bottomCapView];
	[self.view sendSubviewToBack:bottomCapView];

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
	
	[super dealloc];

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

	self.articleAttachmentActivityView.style = !!self.textAttributor.queue.operationCount ? WAArticleAttachmentActivityViewSpinnerStyle :
		[self.article.previews count] ? WAArticleAttachmentActivityViewLinkStyle :
		[self.article.files count] ? WAArticleAttachmentActivityViewAttachmentsStyle :
		WAArticleAttachmentActivityViewDefaultStyle;
		
	[self.articleAttachmentActivityView setTitle:[NSString stringWithFormat:@"%i", [self.article.files count]] forStyle:WAArticleAttachmentActivityViewAttachmentsStyle];
	[self.articleAttachmentActivityView setTitle:[NSString stringWithFormat:@"%i", [self.article.previews count]] forStyle:WAArticleAttachmentActivityViewLinkStyle];

}

- (IRTextAttributor *) textAttributor {

	__block IRTextAttributor *returnedAttributor = [super textAttributor];
	__block __typeof__(self) nrSelf = self;
	__block id observer = [returnedAttributor.queue irAddObserverBlock:^(id inOldValue, id inNewValue, NSString *changeKind) {

		[nrSelf updateArticleAttachmentActivityView];
		
	} forKeyPath:@"operations" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
	
	[returnedAttributor irPerformOnDeallocation:^{
	
	 [returnedAttributor irRemoveObservingsHelper:observer];
		
	}];
	
	return returnedAttributor;

}

- (void) textAttributor:(IRTextAttributor *)attributor willUpdateAttributedString:(NSAttributedString *)attributedString withToken:(NSString *)aToken range:(NSRange)tokenRange attribute:(id)newAttribute {

	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		[super textAttributor:attributor willUpdateAttributedString:attributedString withToken:aToken range:tokenRange attribute:newAttribute];
	
	[self updateArticleAttachmentActivityView];

}

- (void) textAttributor:(IRTextAttributor *)attributor didUpdateAttributedString:(NSAttributedString *)attributedString withToken:(NSString *)aToken range:(NSRange)tokenRange attribute:(id)newAttribute {

	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		[super textAttributor:attributor didUpdateAttributedString:attributedString withToken:aToken range:tokenRange attribute:newAttribute];
	
	[self updateArticleAttachmentActivityView];

}

- (void) handleCurrentArticleFilesChangedFrom:(id)fromValue to:(id)toValue changeKind:(NSString *)changeKind {

	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		[super handleCurrentArticleFilesChangedFrom:fromValue to:toValue changeKind:changeKind];
	
	[self updateArticleAttachmentActivityView];

}

- (void) handleCurrentArticlePreviewsChangedFrom:(id)fromValue to:(id)toValue changeKind:(NSString *)changeKind {

	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		[super handleCurrentArticlePreviewsChangedFrom:fromValue to:toValue changeKind:changeKind];
	
	[self updateArticleAttachmentActivityView];

}

- (void) presentCameraCapturePickerController:(IRImagePickerController *)controller sender:(id)sender {

	[super presentCameraCapturePickerController:controller sender:sender];

}

- (void) handleArticleAttachmentActivityViewTap:(WAArticleAttachmentActivityView *)view {

	switch (view.style) {
	
		case WAArticleAttachmentActivityViewAttachmentsStyle: {
			
			if ([self.article.files count]) {
				
				__block WAAttachedMediaListViewController *mediaList = [[WAAttachedMediaListViewController alloc] initWithArticleURI:[self.article.objectID URIRepresentation] usingContext:self.managedObjectContext completion: ^ {
				
					[mediaList dismissModalViewControllerAnimated:YES];
					
				}];
				
				mediaList.navigationItem.rightBarButtonItem = [IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemAdd wiredAction:^(IRBarButtonItem *senderItem) {
				
					[self handleImageAttachmentInsertionRequestWithSender:senderItem];
					
				}];
				
				mediaList.onViewDidLoad = ^ {
					[mediaList.tableView setEditing:YES animated:NO];
				};
				
				if ([mediaList isViewLoaded])
					mediaList.onViewDidLoad();
				
				WANavigationController *navC = [[[WANavigationController alloc] initWithRootViewController:mediaList] autorelease];
				
				[self presentModalViewController:navC animated:YES];
				
			} else {
			
				[self handleImageAttachmentInsertionRequestWithSender:view];
				
			}
			 
			break;
			
		}
	
		case WAArticleAttachmentActivityViewLinkStyle: {
			
			NSParameterAssert([self.article.previews count]);
			[self inspectPreview:[self.article.previews anyObject]];
			break;
			
		}

		case WAArticleAttachmentActivityViewSpinnerStyle: {
			break;
		}

	}

}

- (void) inspectPreview:(WAPreview *)aPreview {

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
