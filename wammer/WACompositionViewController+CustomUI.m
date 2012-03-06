//
//  WACompositionViewController+CustomUI.m
//  wammer
//
//  Created by Evadne Wu on 11/1/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "Foundation+IRAdditions.h"
#import "UIKit+IRAdditions.h"

#import "WADefines.h"

#import "WACompositionViewController+CustomUI.h"

#import "WANavigationBar.h"
#import "WANavigationController.h"

#import "WAOverlayBezel.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"


@implementation WACompositionViewController (CustomUI)

- (UINavigationController *) wrappingNavigationController {

	NSAssert2(!self.navigationController, @"%@ must not have been put within another navigation controller when %@ is invoked.", self, NSStringFromSelector(_cmd));
	//	NSAssert2((UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()), @"%@: %s is not supported on this device.", self, NSStringFromSelector(_cmd));
	
	WANavigationController *navController = [[[WANavigationController alloc] initWithRootViewController:[[[UIViewController alloc] init] autorelease]] autorelease];
		
	static NSString * const kViewControllerActionOnPop = @"waCompositionViewController_wrappingNavigationController_viewControllerActionOnPop";

	navController.willPushViewControllerAnimated = ^ (WANavigationController *self, UIViewController *pushedVC, BOOL animated) {
		
		if (![pushedVC isKindOfClass:[WACompositionViewController class]])
			return;
		
		((WACompositionViewController *)pushedVC).usesTransparentBackground = YES;
		
		UIBarButtonItem *oldLeftItem = pushedVC.navigationItem.leftBarButtonItem;
		UIBarButtonItem *oldRightItem = pushedVC.navigationItem.rightBarButtonItem;
		
		__block id leftTarget = oldLeftItem.target;
		__block SEL leftAction = oldLeftItem.action;
		
		__block id rightTarget = oldRightItem.target;
		__block SEL rightAction = oldRightItem.action;
		
		__block IRBarButtonItem *newLeftItem = WABackBarButtonItem(nil, NSLocalizedString(@"ACTION_BACK", @"Action title for cancelling"), ^{
			[leftTarget performSelector:leftAction withObject:newLeftItem];
		});
		
		__block IRBarButtonItem *newRightItem = WABarButtonItem(nil, NSLocalizedString(@"ACTION_DONE", @"Action title for done"), ^{
			[rightTarget performSelector:rightAction withObject:newRightItem];
		});
		
		pushedVC.navigationItem.leftBarButtonItem = newLeftItem;		
		pushedVC.navigationItem.rightBarButtonItem = newRightItem;
		
		if (!pushedVC.navigationItem.titleView) {
		
			__block UILabel *titleLabel = WAStandardTitleLabel();
			
			[titleLabel irBind:@"text" toObject:pushedVC keyPath:@"title" options:[NSDictionary dictionaryWithObjectsAndKeys:
				
				[[^ (id oldValue, id newValue, NSString *changeType) {
					
					titleLabel.text = newValue;
					
					titleLabel.bounds = (CGRect){
						CGPointZero,
						(CGSize){
							[titleLabel sizeThatFits:(CGSize){ 1024, 1024 }].width,
							36
						}
					};
					
					return newValue;
				
				} copy] autorelease], kIRBindingsValueTransformerBlock,
				
				kCFBooleanTrue, kIRBindingsAssignOnMainThreadOption,
			
			nil]];
			
			objc_setAssociatedObject(pushedVC, &kViewControllerActionOnPop, ^ {
			
				[titleLabel irUnbind:@"text"];
			
			}, OBJC_ASSOCIATION_COPY_NONATOMIC);
			
			pushedVC.navigationItem.titleView = titleLabel;

		}
		
		if (![pushedVC isViewLoaded])
			return;
			
		pushedVC.view.backgroundColor = nil;
		pushedVC.view.opaque = NO;
		
	};
	
	navController.onDismissModalViewControllerAnimated = ^ (WANavigationController *self, BOOL animated) {
	
		void (^action)() = objc_getAssociatedObject(self.topViewController, &kViewControllerActionOnPop);
		if (action)
				action();
		
	};
	
	[navController performSelector:@selector(initWithRootViewController:) withObject:self];
	
	navController.onViewDidLoad = ^ (WANavigationController *self) {
	
		WANavigationBar *navBar = ((WANavigationBar *)self.navigationBar);
	
		//	switch ([UIDevice currentDevice].userInterfaceIdiom) {
		//		case UIUserInterfaceIdiomPad: {
		//			navBar.customBackgroundView = [WANavigationBar defaultGradientBackgroundView];
		//			break;
		//		}
		//		case UIUserInterfaceIdiomPhone: {
		//			navBar.customBackgroundView = [WANavigationBar defaultPatternBackgroundView];
		//			break;
		//		}
		//	}
		
		navBar.customBackgroundView = [WANavigationBar defaultPatternBackgroundView];
		
		self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPatternWoodTexture"]];
		
		UIColor *baseColor = [UIColor colorWithRed:.75 green:.65 blue:.52 alpha:1];
		
		IRGradientView *gradientView = [[[IRGradientView alloc] initWithFrame:(CGRect){ CGPointZero, (CGSize){ CGRectGetWidth(self.view.frame), 512 } }] autorelease];
		[gradientView setLinearGradientFromColor:[baseColor colorWithAlphaComponent:1] anchor:irTop toColor:[baseColor colorWithAlphaComponent:0] anchor:irBottom];
		
		gradientView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
		
		[self.view addSubview:gradientView];
		[self.view sendSubviewToBack:gradientView];
					
	};
	
	if ([navController isViewLoaded])
		navController.onViewDidLoad(navController);
	
	return navController;

}

+ (WACompositionViewController *) defaultAutoSubmittingCompositionViewControllerForArticle:(NSURL *)anArticleURI completion:(void(^)(NSURL *))aBlock {

	__block WACompositionViewController *compositionVC = [WACompositionViewController controllerWithArticle:anArticleURI completion:^(NSURL *anArticleURLOrNil) {
	
		if (aBlock)
			aBlock(anArticleURLOrNil);
				
		if (!anArticleURLOrNil)
			return;
	
		WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
		[busyBezel show];
	
		[[WADataStore defaultStore] uploadArticle:anArticleURLOrNil onSuccess: ^ {
		
			dispatch_async(dispatch_get_main_queue(), ^ {
			
				[busyBezel dismiss];

				WAOverlayBezel *doneBezel = [WAOverlayBezel bezelWithStyle:WACheckmarkBezelStyle];
				[doneBezel show];
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^ {
					[doneBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
				});
				
			});		
		
		} onFailure: ^ (NSError *error) {
		
			dispatch_async(dispatch_get_main_queue(), ^ {
			
				[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade|WAOverlayBezelAnimationZoom];
				
				WAOverlayBezel *errorBezel = [WAOverlayBezel bezelWithStyle:WAErrorBezelStyle];
				[errorBezel show];
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^ {
					[errorBezel dismiss];
				});
				
				if (error) {
				
					NSString *title = NSLocalizedString(@"ERROR_ARTICLE_ENTITY_SYNC_FAILURE_TITLE", @"Article entity sync failure alert title");
					NSString *errorDescription = [error localizedDescription];
					NSString *errorReason = [error localizedFailureReason];
					NSString *message = nil;
					
					if (errorDescription && errorReason) {
						
						message = [NSString stringWithFormat:NSLocalizedString(@"ERROR_ARTICLE_ENTITY_SYNC_FAILURE_WITH_UNDERLYING_ERROR_DESCRIPTION_AND_REASON_FORMAT", @"Failed, underlying error %@ with reason %@"), errorDescription, errorReason];
						
					} else if (errorDescription) {

						message =  [NSString stringWithFormat:NSLocalizedString(@"ERROR_ARTICLE_ENTITY_SYNC_FAILURE_WITH_UNDERLYING_ERROR_DESCRIPTION_FORMAT", @"Failed, underlying error description %@"), errorDescription]; 
					
					} else {
					
						message = NSLocalizedString(@"ERROR_ARTICLE_ENTITY_SYNC_FAILURE_DESCRIPTION", @"Article entity sync failure alert message for no underlying error");
					
					}
					
					[[[[IRAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ACTION_OKAY", nil), nil] autorelease] show];
				
				}
			
			});
					
		}];
	
	}];
	
	return compositionVC;

}

@end
