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

#import "WANavigationController.h"

#import "WAOverlayBezel.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"
#import "WARemoteInterface.h"

@implementation WACompositionViewController (CustomUI)

- (UINavigationController *) wrappingNavigationController {

	NSAssert2(!self.navigationController, @"%@ must not have been put within another navigation controller when %@ is invoked.", self, NSStringFromSelector(_cmd));
	
	return [[WANavigationController alloc] initWithRootViewController:self];

}

+ (WACompositionViewController *) defaultAutoSubmittingCompositionViewControllerForArticle:(NSURL *)anArticleURI completion:(void(^)(NSURL *))aBlock {
  
  return [WACompositionViewController controllerWithArticle:anArticleURI completion:^(WAArticle *anArticleOrNil, NSManagedObjectContext *moc) {

	void (^showSuccessBezel) () = ^() {
	  WAOverlayBezel *doneBezel = [WAOverlayBezel bezelWithStyle:WACheckmarkBezelStyle];
	  [doneBezel show];
	  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^ {
		[doneBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
		
		if (aBlock)
		  aBlock([[anArticleOrNil objectID] URIRepresentation]);
		
	  });
	};
	
	void (^showErrorBezel) () = ^() {
	  WAOverlayBezel *errorBezel = [WAOverlayBezel bezelWithStyle:WAErrorBezelStyle];
	  [errorBezel  show];
	  int64_t delayInSeconds = 2.0;
	  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[errorBezel dismiss];
		if (aBlock)
		  aBlock([[anArticleOrNil objectID] URIRepresentation]);
	  });
	  
	};

	if (!anArticleOrNil) {
	  if (aBlock)
		aBlock(nil);
	  return;
	}
	
	if (!([anArticleOrNil hasChanges] && [[anArticleOrNil changedValues] count])) {
	  // Nothing change
	  if (aBlock)
		aBlock(nil);
	  return;
	}
	
	WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
	[busyBezel show];
		
	WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	NSMutableArray *attachments = [NSMutableArray array];
	for (WAFile *file in anArticleOrNil.files) {
	  [attachments addObject:file.identifier];
	}
	
	NSString *postCoverPhotoId = nil;
	if (attachments.count)
	  postCoverPhotoId = attachments[0];
	  
	[ri updatePost:anArticleOrNil.identifier
		   inGroup:ri.primaryGroupIdentifier
		  withText:anArticleOrNil.text
	   attachments:attachments
	mainAttachment:postCoverPhotoId
		   type:WAArticleTypeEvent
		  favorite:NO
			hidden:NO
replacingDataWithDate:anArticleOrNil.modificationDate
		updateTime:nil
		 onSuccess:^(NSDictionary *postRep) {

		   NSError *savingError = nil;
		   if (![moc save:&savingError]) {
			 
			 NSLog(@"Error saving: %@", savingError);
			 dispatch_async(dispatch_get_main_queue(), ^{
			   [busyBezel dismiss];
			   showErrorBezel();
			 });
			 
		   } else {
	  	  
			 dispatch_async(dispatch_get_main_queue(), ^ {
		  
			   [busyBezel dismiss];
			   showSuccessBezel();
		  
			 });
			 
		   }

		 } onFailure:^(NSError *error) {
		
		   dispatch_async(dispatch_get_main_queue(), ^ {
		
			 [busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade|WAOverlayBezelAnimationZoom];
		  
			 showErrorBezel();
		
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
