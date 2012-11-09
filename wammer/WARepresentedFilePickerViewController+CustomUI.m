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

+ (WARepresentedFilePickerViewController *) defaultAutoSubmittingControllerForArticle:(NSURL *)anArticleURI completion:(void(^)(NSURL *fileEntityURI))aBlock {

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
		
		NSAssert1(pickedFile.articles.count>0, @"WAFile entity %@ must have already been associated with an article", pickedFile);
		WAArticle *article = [[pickedFile.articles allObjects] objectAtIndex:0];
		
		article.representingFile = pickedFile;
		article.dirty = (id)kCFBooleanTrue;
		if (article.modificationDate) {
			// set modification only when updating articles
			article.modificationDate = [NSDate date];
		}
		
		NSCParameterAssert(article.representingFile == pickedFile);
		
		NSError *savingError = nil;
		if (![article.managedObjectContext save:&savingError]) {
			
			NSLog(@"Error saving: %@", savingError);
			
			if (aBlock)
				aBlock(nil);
			
			return;
			
		}
		
		aBlock(selectedFileURI);
		
		[[WARemoteInterface sharedInterface] beginPostponingDataRetrievalTimerFiring];
	
		[[WADataStore defaultStore] updateArticle:[[article objectID] URIRepresentation] withOptions:nil onSuccess:^{
		
			NSParameterAssert([NSThread isMainThread]);
			
			[[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
			
		} onFailure:^(NSError *error) {
			
			NSParameterAssert([NSThread isMainThread]);

			[[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
			
		}];

	}];
	
	return nil;

}

+ (BOOL) canPresentRepresentedFilePickerControllerForArticle:(NSURL *)anArticleURI {

	WAArticle *article = (WAArticle *)[[[WADataStore defaultStore] defaultAutoUpdatedMOC] irManagedObjectForURI:anArticleURI];
	
	return ([article.files count] >= 2);

}

@end
