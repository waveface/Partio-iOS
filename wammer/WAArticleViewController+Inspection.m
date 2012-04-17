//
//  WAArticleViewController+Inspection.m
//  wammer
//
//  Created by Evadne Wu on 3/29/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <objc/runtime.h>
#import "WAArticleViewController+Inspection.h"
#import "WADataStore.h"
#import "UIApplication+CrashReporting.h"
#import "UIKit+IRAdditions.h"
#import "WAArticleFilesListViewController.h"
#import "WADefines.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"
#import "WAOverlayBezel.h"
#import "WARemoteInterface.h"
#import "WARepresentedFilePickerViewController.h"
#import "WARepresentedFilePickerViewController+CustomUI.h"


static NSString * const kInspectionDelegate = @"-[WAArticleViewController(Inspection) inspectionDelegate]";
static NSString * const kInspectionActionSheetController = @"-[WAArticleViewController(Inspection) inspectionActionSheetController]";
static NSString * const kCoverPhotoSwitchPopoverController = @"-[WAArticleViewController(Inspection)] coverPhotoSwitchPopoverController]";


@implementation WAArticleViewController (Inspection)

- (id<WAArticleViewControllerInspection>) inspectionDelegate {

	return objc_getAssociatedObject(self, &kInspectionDelegate);

}

- (void) setInspectionDelegate:(id<WAArticleViewControllerInspection>)newInspectionDelegate {

	objc_setAssociatedObject(self, &kInspectionDelegate, newInspectionDelegate, OBJC_ASSOCIATION_ASSIGN);

}

- (UILongPressGestureRecognizer *) newInspectionGestureRecognizer {

	UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleInspectionGestureRecognizer:)];
	
	recognizer.minimumPressDuration = 0.125;
	
	return recognizer;

}

- (NSArray *) newInspectionActions {

	NSMutableArray *baseActions = [NSMutableArray arrayWithObjects:
		
		[self newFavoriteStatusToggleAction],
		
	nil];
	
	IRAction *coverPhotoSwitchAction = [self newCoverPhotoSwitchAction];
	if (coverPhotoSwitchAction)
		[baseActions addObject:coverPhotoSwitchAction];
	
	IRAction *deleteAction = [self newDeleteArticleAction];
	if (deleteAction)
		[baseActions addObject:deleteAction];
	
	if (WAAdvancedFeaturesEnabled())
		[baseActions addObject:[self newInspectionAction]];
	
	if (self.inspectionDelegate)
		return [self.inspectionDelegate actionsForArticleViewController:self basedOn:baseActions];

	return baseActions;

}

- (void) handleInspectionGestureRecognizer:(UILongPressGestureRecognizer *)longPressRecognizer {

	if (longPressRecognizer.state != UIGestureRecognizerStateBegan)
		return;
	
	IRActionSheetController *controller = objc_getAssociatedObject(self, &kInspectionActionSheetController);
	if ([controller.managedActionSheet isVisible])
		return;
	
	self.inspectionActionSheetController = nil;
	[self.inspectionActionSheetController.managedActionSheet showFromRect:CGRectOffset((CGRect){
		
		[longPressRecognizer locationInView:self.view],
		(CGSize){ 44, 44 }
		
	}, -22, -22) inView:self.view animated:YES];
	
}

- (IRActionSheetController *) inspectionActionSheetController {

	IRActionSheetController *controller = objc_getAssociatedObject(self, &kInspectionActionSheetController);
	
	if (!controller) {

		NSArray *actions = [self newInspectionActions];
		
		if (![actions count])
			return nil;

		controller = [IRActionSheetController actionSheetControllerWithTitle:nil cancelAction:nil destructiveAction:nil otherActions:actions];
		controller.managedActionSheet.dismissesOnOrientationChange = YES;
		
		self.inspectionActionSheetController = controller;
		
	}
	
	return controller;

}

- (void) setInspectionActionSheetController:(IRActionSheetController *)controller {

	objc_setAssociatedObject(self, &kInspectionActionSheetController, controller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

}

- (IRAction *) newInspectionAction {

	__weak WAArticleViewController *wSelf = self;

	return [IRAction actionWithTitle:@"Inspect" block: ^ {
		
		dispatch_async(dispatch_get_current_queue(), ^ {
		
			NSString *inspectionText = [NSString stringWithFormat:@"Article: %@\nFiles: %@\nFileOrder: %@\nComments: %@", self.article, self.article.files, self.article.fileOrder, self.article.comments];
			NSURL *articleURI = [[self.article objectID] URIRepresentation];
			BOOL articleHasFiles = !![self.article.fileOrder count];
			
			if (wSelf.onPresentingViewController) {

				IRViewController *shownViewController = [[IRViewController alloc] init];
				__weak IRViewController *wShownViewController = shownViewController;
				
				shownViewController.onLoadView = ^ {
					wShownViewController.view = [[UIView alloc] initWithFrame:CGRectZero];
					UITextView *textView = [[UITextView alloc] initWithFrame:wShownViewController.view.bounds];
					textView.text = inspectionText;
					textView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
					textView.editable = NO;
					[wShownViewController.view addSubview:textView];
				};
				
				shownViewController.onShouldAutorotateToInterfaceOrientation = ^ (UIInterfaceOrientation toOrientation) {
					return YES;
				};
				
				__block UINavigationController *shownNavController = [[UINavigationController alloc] initWithRootViewController:shownViewController];
				shownNavController.modalPresentationStyle = UIModalPresentationFormSheet;
				
				shownViewController.title = @"Inspect";
				
				shownViewController.navigationItem.leftBarButtonItem = [IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemDone wiredAction:^(IRBarButtonItem *senderItem) {
				
					[shownNavController dismissModalViewControllerAnimated:YES];
					
				}];
				
				shownViewController.navigationItem.rightBarButtonItem = [IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemAction wiredAction:^(IRBarButtonItem *senderItem) {
				
					IRAction *emailAction = [IRAction actionWithTitle:@"Email" block:^{
				
						NSArray *mailRecipients = [[UIApplication sharedApplication] crashReportRecipients];
						
						NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
						NSString *versionString = [NSString stringWithFormat:@"%@ %@ (%@) Commit %@", [bundleInfo objectForKey:(id)kCFBundleNameKey], [bundleInfo objectForKey:@"CFBundleShortVersionString"], [bundleInfo objectForKey:(id)kCFBundleVersionKey], [bundleInfo objectForKey:@"IRCommitSHA"]];
						
						NSString *mailSubject = [NSString stringWithFormat:@"Inspected Article — %@", versionString];
						
						__block IRMailComposeViewController *mailComposeController = [IRMailComposeViewController controllerWithMessageToRecipients:mailRecipients withSubject:mailSubject messageBody:inspectionText inHTML:NO completion:^(MFMailComposeViewController *controller, MFMailComposeResult result, NSError *error) {
						
							[mailComposeController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
							
						}];
						
						mailComposeController.modalPresentationStyle = UIModalPresentationFormSheet;
						
						[CATransaction begin];
						
						CATransition *transition = [CATransition animation];
						transition.type = kCATransitionFade;
						transition.duration = 0.3f;
						transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
						transition.fillMode = kCAFillModeForwards;
						transition.removedOnCompletion = YES;
						
						[shownViewController.navigationController presentModalViewController:mailComposeController animated:NO];
						[shownViewController.navigationController.view.window.layer addAnimation:transition forKey:kCATransition];
						
						[CATransaction commit];
						
					}];
					
					IRActionSheetController *actionSheetController = [IRActionSheetController actionSheetControllerWithTitle:nil cancelAction:nil destructiveAction:nil otherActions:((^ {
						
						NSMutableArray *availableActions = [NSMutableArray arrayWithObject:emailAction];
						
						if (articleHasFiles) {
							[availableActions addObject:[IRAction actionWithTitle:@"Files" block:^{
								[shownViewController.navigationController pushViewController:[WAArticleFilesListViewController controllerWithArticle:articleURI] animated:YES];
							}]];
						}
						
						return availableActions;
						
					})())];
					
					[[actionSheetController managedActionSheet] showFromBarButtonItem:senderItem animated:NO];
					
				}];
				
				wSelf.onPresentingViewController( ^ (UIViewController <WAArticleViewControllerPresenting> *parentViewController) {
					[parentViewController presentModalViewController:shownNavController animated:YES];
				});
			
			} else {
		
				[[[IRAlertView alloc] initWithTitle:@"Inspect" message:inspectionText delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
			
			}
			
		});
		
	}];

}

- (IRAction *) newFavoriteStatusToggleAction {

	BOOL isFavorite = [self.article.favorite isEqualToNumber:(NSNumber *)kCFBooleanTrue];
	NSString *actionTitle = isFavorite ? NSLocalizedString(@"ACTION_UNMARK_FAVORITE", nil) : NSLocalizedString(@"ACTION_MARK_FAVORITE", nil);
	
	__weak WAArticleViewController *wSelf = self;
	
	return [IRAction actionWithTitle:actionTitle block:^{
	
		__block BOOL hasRunAction = NO;
		
		void (^action)(void) = ^ {
		
			WAArticle *article = wSelf.article;
			
			article.favorite = (NSNumber *)([article.favorite isEqual:(id)kCFBooleanTrue] ? kCFBooleanFalse : kCFBooleanTrue);
			article.modificationDate = [NSDate date];
			
			NSError *savingError = nil;
			if (![article.managedObjectContext save:&savingError])
				NSLog(@"Error saving: %@", savingError);
				
			[[WARemoteInterface sharedInterface] beginPostponingDataRetrievalTimerFiring];
			
			[[WADataStore defaultStore] updateArticle:[[article objectID] URIRepresentation] withOptions:[NSDictionary dictionaryWithObjectsAndKeys:
				
				(id)kCFBooleanTrue, kWADataStoreArticleUpdateShowsBezels,
				
			nil] onSuccess:^{
				
				[[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
				
			} onFailure:^(NSError *error) {
				
				[[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
				
			}];

		};
	
		if (wSelf.onPresentingViewController) {
		
			wSelf.onPresentingViewController(^(UIViewController <WAArticleViewControllerPresenting> *parentViewController) {
				
				if (![parentViewController respondsToSelector:@selector(enqueueInterfaceUpdate:sender:)])
					return;
				
				hasRunAction = YES;
				
				[parentViewController enqueueInterfaceUpdate:action sender:wSelf];

			});
		
		}
		
		if (!hasRunAction)
			action();
	
	}];

}

- (IRAction *) newCoverPhotoSwitchAction {

	__weak WAArticleViewController *wSelf = self;
	
	NSURL *objectURI = [[self.article objectID] URIRepresentation];
	
	if (![WARepresentedFilePickerViewController canPresentRepresentedFilePickerControllerForArticle:objectURI])
		return nil;
	
	return [IRAction actionWithTitle:NSLocalizedString(@"ACTION_CHANGE_REPRESENTING_FILE", @"Title for the action responsible for presenting a controller changing the representing file of an article") block:^{
	
		UIPopoverController *popoverController = wSelf.coverPhotoSwitchPopoverController;
		if ([popoverController isPopoverVisible])
			return;
		
		[popoverController presentPopoverFromRect:self.view.bounds inView:wSelf.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		
	}];

}

- (IRAction *) newDeleteArticleAction {

	__weak WAArticleViewController *wSelf = self;
	
	NSString *deleteActionTitle = NSLocalizedString(@"ACTION_DELETE", @"Title for deleting an article from the Overview");
	NSString *cancelActionTitle = NSLocalizedString(@"ACTION_CANCEL", @"Title for cancelling an action");
	NSString *deleteConfirmationTitle = NSLocalizedString(@"DELETE_POST_CONFIRMATION_TITLE", @"Title for confirming a post deletion");
	NSString *deleteConfirmationMessage = NSLocalizedString(@"DELETE_POST_CONFIRMATION_DESCRIPTION", @"Description for confirming a post deletion");

	return [IRAction actionWithTitle:deleteActionTitle block:^{
	
		IRAction *deleteAction = [IRAction actionWithTitle:deleteActionTitle block:^ {
		
			WAArticle *article = wSelf.article;
		
			article.hidden = (id)kCFBooleanTrue;
			article.modificationDate = [NSDate date];
			
			NSError *savingError = nil;
			if (![article.managedObjectContext save:&savingError])
				NSLog(@"Error saving: %@", savingError);
			
			[[WARemoteInterface sharedInterface] beginPostponingDataRetrievalTimerFiring];
			
			[[WADataStore defaultStore] updateArticle:[[article objectID] URIRepresentation] withOptions:[NSDictionary dictionaryWithObjectsAndKeys:
				
				(id)kCFBooleanTrue, kWADataStoreArticleUpdateShowsBezels,
				(id)kCFBooleanTrue, kWADataStoreArticleUpdateVisibilityOnly,
				
			nil] onSuccess:^{
				
				[[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
				
			} onFailure:^(NSError *error) {
				
				[[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
				
			}];
		
		}];
		
		IRAction *cancelAction = [IRAction actionWithTitle:cancelActionTitle block:nil];
		
		CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopDefaultMode, ^{
			
			[[IRAlertView alertViewWithTitle:deleteConfirmationTitle message:deleteConfirmationMessage cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:deleteAction, nil]] show];
			
		});
		
	}];
	
}

- (UIPopoverController *) coverPhotoSwitchPopoverController {

	UIPopoverController *popoverController = objc_getAssociatedObject(self, &kCoverPhotoSwitchPopoverController);
	if (!popoverController) {

		NSURL *objectURI = [[self.article objectID] URIRepresentation];
		
		__weak WAArticleViewController *wSelf = self;
	
		WARepresentedFilePickerViewController *controller = [WARepresentedFilePickerViewController defaultAutoSubmittingControllerForArticle:objectURI completion: ^ (NSURL *selectedFileURI) {
			
			UIPopoverController *foundPopoverController = wSelf ? objc_getAssociatedObject(wSelf, &kCoverPhotoSwitchPopoverController) : nil;
			if ([foundPopoverController isPopoverVisible])
				[foundPopoverController dismissPopoverAnimated:YES];
			
		}];
		
		UINavigationController *navC = [controller wrappingNavigationController];
		popoverController = [[UIPopoverController alloc] initWithContentViewController:navC];
		
		self.coverPhotoSwitchPopoverController = popoverController;
		
		__weak UIPopoverController *wPopoverController = popoverController;
		
		__block id orientationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidChangeStatusBarOrientationNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
		
			if (![wPopoverController isPopoverVisible])
				return;
			
			[wPopoverController dismissPopoverAnimated:NO];
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
				
				[wPopoverController presentPopoverFromRect:wSelf.view.bounds inView:wSelf.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
			
			});
			
		}];
		
		[popoverController irPerformOnDeallocation:^{
			
			[[NSNotificationCenter defaultCenter] removeObserver:orientationObserver];
			orientationObserver = nil;
			
		}];
	
	}
	
	return popoverController;

}

- (void) setCoverPhotoSwitchPopoverController:(UIPopoverController *)coverPhotoSwitchPopoverController {

	objc_setAssociatedObject(self, &kCoverPhotoSwitchPopoverController, coverPhotoSwitchPopoverController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

}

@end
