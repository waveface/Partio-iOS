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
#import "WAViewController.h"
#import "UIApplication+CrashReporting.h"
#import "UIKit+IRAdditions.h"
#import "WAArticleFilesListViewController.h"
#import "WADefines.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"
#import "WAOverlayBezel.h"
#import "WARemoteInterface.h"


NSString * const kInspectionDelegate = @"WAArticleViewController_Inspection_inspectionDelegate";


@implementation WAArticleViewController (Inspection)

- (id<WAArticleViewControllerInspection>) inspectionDelegate {

	return objc_getAssociatedObject(self, &kInspectionDelegate);

}

- (void) setInspectionDelegate:(id<WAArticleViewControllerInspection>)newInspectionDelegate {

	objc_setAssociatedObject(self, &kInspectionDelegate, newInspectionDelegate, OBJC_ASSOCIATION_ASSIGN);

}

- (UILongPressGestureRecognizer *) newInspectionGestureRecognizer {

	UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleInspectionGestureRecognizer:)];
	
	return recognizer;

}

- (NSArray *) newInspectionActions {

	NSMutableArray *baseActions = [NSMutableArray arrayWithObjects:
		
		[self newFavoriteStatusToggleAction],
		
	nil];
	
	if (WAAdvancedFeaturesEnabled())
		[baseActions addObject:[self newInspectionAction]];
	
	if (self.inspectionDelegate)
		return [self.inspectionDelegate actionsForArticleViewController:self basedOn:baseActions];

	return baseActions;

}

- (void) handleInspectionGestureRecognizer:(UILongPressGestureRecognizer *)longPressRecognizer {

	if (longPressRecognizer.state != UIGestureRecognizerStateRecognized)
		return;

	static NSString * const kGlobalInspectActionSheet = @"kGlobalInspectActionSheet";
	
	__block IRActionSheetController *controller = objc_getAssociatedObject(self, &kGlobalInspectActionSheet);
	
	if (controller)
	if ([(UIActionSheet *)[controller managedActionSheet] isVisible])
		return;
	
	NSArray *actions = [self newInspectionActions];
	
	if (![actions count])
		return;
	
	controller = [IRActionSheetController actionSheetControllerWithTitle:nil cancelAction:nil destructiveAction:nil otherActions:actions];

	objc_setAssociatedObject(self, &kGlobalInspectActionSheet, controller, OBJC_ASSOCIATION_RETAIN);
	
	[(UIActionSheet *)[controller managedActionSheet] showFromRect:(CGRect){
		(CGPoint){
			CGRectGetMidX(self.view.bounds),
			CGRectGetMidY(self.view.bounds)
		},
		(CGSize){ 2, 2 }
	} inView:self.view animated:YES];
	
	((IRActionSheet *)[controller managedActionSheet]).dismissesOnOrientationChange = YES;

}

- (IRAction *) newInspectionAction {

	__weak WAArticleViewController *nrSelf = self;

	return [IRAction actionWithTitle:@"Inspect" block: ^ {
		
		dispatch_async(dispatch_get_current_queue(), ^ {
		
			NSString *inspectionText = [NSString stringWithFormat:@"Article: %@\nFiles: %@\nFileOrder: %@\nComments: %@", self.article, self.article.files, self.article.fileOrder, self.article.comments];
			NSURL *articleURI = [[self.article objectID] URIRepresentation];
			BOOL articleHasFiles = !![self.article.fileOrder count];
			
			if (nrSelf.onPresentingViewController) {

				__block WAViewController *shownViewController = [[WAViewController alloc] init];
				shownViewController.onLoadview = ^ (WAViewController *self) {
					self.view = [[UIView alloc] initWithFrame:CGRectZero];
					UITextView *textView = [[UITextView alloc] initWithFrame:self.view.bounds];
					textView.text = inspectionText;
					textView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
					textView.editable = NO;
					[self.view addSubview:textView];
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
				
				nrSelf.onPresentingViewController( ^ (UIViewController <WAArticleViewControllerPresenting> *parentViewController) {
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
				
				dispatch_async(dispatch_get_main_queue(), ^{
					
					[parentViewController enqueueInterfaceUpdate:action sender:wSelf];
				
				});

			});
		
		}
		
		if (!hasRunAction)
			action();
	
	}];

}

@end
