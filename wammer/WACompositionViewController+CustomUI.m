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
	
	return [[WANavigationController alloc] initWithRootViewController:self];

}

+ (WACompositionViewController *) defaultAutoSubmittingCompositionViewControllerForArticle:(NSURL *)anArticleURI completion:(void(^)(NSURL *))aBlock {

	return [WACompositionViewController controllerWithArticle:anArticleURI completion:^(NSURL *anArticleURLOrNil) {
	
		if (aBlock)
			aBlock(anArticleURLOrNil);
				
		if (!anArticleURLOrNil)
			return;
	
		WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
		[busyBezel show];
	
		[[WADataStore defaultStore] updateArticle:anArticleURLOrNil onSuccess: ^ {
		
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
					
					[[[IRAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"ACTION_OKAY", nil), nil] show];
				
				}
			
			});
					
		}];
	
	}];

}

@end
