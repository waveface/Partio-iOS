//
//  WARepresentedFilePickerViewController+CustomUI.m
//  wammer
//
//  Created by Evadne Wu on 4/9/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARepresentedFilePickerViewController+CustomUI.h"
#import "WANavigationController.h"
#import "WARemoteInterface.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

@implementation WARepresentedFilePickerViewController (CustomUI)

- (UINavigationController *) wrappingNavigationController {

	NSAssert2(!self.navigationController, @"%@ must not have been put within another navigation controller when %@ is invoked.", self, NSStringFromSelector(_cmd));
	
	return [[WANavigationController alloc] initWithRootViewController:self];

}

+ (WARepresentedFilePickerViewController *) defaultAutoSubmittingControllerForArticle:(NSURL *)anArticleURI completion:(void(^)(NSURL *))aBlock {

	if (![self canPresentRepresentedFilePickerControllerForArticle:anArticleURI])
		return nil;

	return [self controllerWithObjectURI:anArticleURI completion:^(NSURL *selectedFileURI) {
	
		if (!selectedFileURI) {
			
			if (aBlock)
				aBlock(nil);
			
			return;	//	Probably cancelled, in that case, do nothing
			
		}
		
		NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
		WAFile *pickedFile = (WAFile *)[context irManagedObjectForURI:selectedFileURI];
		NSAssert1(pickedFile, @"WAFile entity referneced by URL %@ must exist", selectedFileURI);
		
		WAArticle *article = pickedFile.article;
		NSAssert1(article, @"WAFile entity %@ must have already been associated with an article", pickedFile);
		
		article.representingFile = pickedFile;
		article.modificationDate = [NSDate date];
		
		NSError *savingError = nil;
		if (![article.managedObjectContext save:&savingError]) {
			NSLog(@"Error saving: %@", savingError);
			//	Callback?
			abort();	//	Foolish
		}
		
		[[WARemoteInterface sharedInterface] beginPostponingDataRetrievalTimerFiring];
	
		[[WADataStore defaultStore] updateArticle:[[article objectID] URIRepresentation] withOptions:[NSDictionary dictionaryWithObjectsAndKeys:
			
			(id)kCFBooleanTrue, kWADataStoreArticleUpdateShowsBezels,
			
		nil] onSuccess:^{
		
			NSParameterAssert([NSThread isMainThread]);
			
			[[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
			aBlock(selectedFileURI);
			
		} onFailure:^(NSError *error) {
			
			NSParameterAssert([NSThread isMainThread]);

			[[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
			aBlock(selectedFileURI);
			
		}];

	}];
	
	return nil;

}

+ (BOOL) canPresentRepresentedFilePickerControllerForArticle:(NSURL *)anArticleURI {

	WAArticle *article = (WAArticle *)[[[WADataStore defaultStore] defaultAutoUpdatedMOC] irManagedObjectForURI:anArticleURI];
	
	return ([article.files count] >= 2);

}

@end
