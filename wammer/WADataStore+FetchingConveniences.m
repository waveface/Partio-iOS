//
//  WADataStore+FetchingConveniences.m
//  wammer
//
//  Created by Evadne Wu on 12/14/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADataStore+FetchingConveniences.h"

@implementation WADataStore (FetchingConveniences)

- (NSFetchRequest *) newFetchRequestForUsersWithIdentifier:(NSString *)identifier {

	NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRUser" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
		identifier, @"Identifier",
	nil]];
	
	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
    [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO],
	nil];
	
	return fetchRequest;

}

- (NSFetchRequest *) newFetchRequestForAllArticles {

	NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRArticles" substitutionVariables:[NSDictionary dictionary]];
	
	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
    //[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:NO],
		[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO],
	nil];
	
	fetchRequest.relationshipKeyPathsForPrefetching = [NSArray arrayWithObjects:
		@"files",
		@"files.pageElements",
		@"previews",
		@"previews.graphElement",
		@"previews.graphElement.images",
	nil];
	
	fetchRequest.fetchBatchSize = 100;
	
	fetchRequest.displayTitle = NSLocalizedString(@"FETCH_REQUEST_ALL_ARTICLES_DISPLAY_TITLE", @"Display title for a fetch request working against all the articles");
	
	return fetchRequest;

}

- (NSFetchRequest *) newFetchRequestForOldestArticle {

	NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRArticles" substitutionVariables:[NSDictionary dictionary]];
	
	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
    [NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:YES],
		[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES],
	nil];
	
	fetchRequest.relationshipKeyPathsForPrefetching = [NSArray arrayWithObjects:
		@"files",
		@"files.pageElements",
		@"previews",
		@"previews.graphElement",
		@"previews.graphElement.images",
	nil];
	
	fetchRequest.fetchBatchSize = 1;
	fetchRequest.fetchLimit = 1;
	
	return fetchRequest;

}

- (NSFetchRequest *) newFetchRequestForOldestArticleAfterDate:(NSDate*)date {
	
	NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRArticles" substitutionVariables:[NSDictionary dictionary]];
	
	fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:
																																							 
																																							 fetchRequest.predicate,
																																							 
																																							 [NSPredicate predicateWithFormat:@"(creationDate >= %@)", date],
																																							 
																																							 nil]];

	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
																	[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES],
																	nil];
	
	fetchRequest.relationshipKeyPathsForPrefetching = [NSArray arrayWithObjects:
																										 @"files",
																										 @"files.pageElements",
																										 @"previews",
																										 @"previews.graphElement",
																										 @"previews.graphElement.images",
																										 nil];
	
	fetchRequest.fetchBatchSize = 1;
	fetchRequest.fetchLimit = 1;
	
	return fetchRequest;
	
}


- (NSFetchRequest *) newFetchRequestForNewestArticle {

	NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRArticles" substitutionVariables:[NSDictionary dictionary]];
	
	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
		[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO],
	nil];
	
	fetchRequest.relationshipKeyPathsForPrefetching = [NSArray arrayWithObjects:
		@"files",
		@"files.pageElements",
		@"previews",
		@"previews.graphElement",
		@"previews.graphElement.images",
	nil];
	
	fetchRequest.fetchBatchSize = 1;
	fetchRequest.fetchLimit = 1;
	
	return fetchRequest;

}

- (NSFetchRequest *) newFetchRequestForNewestArticleOnDate:(NSDate *)date {

	NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRArticles" substitutionVariables:[NSDictionary dictionary]];
	
	fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:
	
		fetchRequest.predicate,
	
		[NSPredicate predicateWithFormat:@"(creationDate <= %@)", date],
	
	nil]];
	
	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
    [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO],
	nil];
	
	fetchRequest.relationshipKeyPathsForPrefetching = [NSArray arrayWithObjects:
		@"files",
		@"files.pageElements",
		@"previews",
		@"previews.graphElement",
		@"previews.graphElement.images",
	nil];
	
	fetchRequest.fetchBatchSize = 1;
	fetchRequest.fetchLimit = 1;
	
	fetchRequest.displayTitle = NSLocalizedString(@"FETCH_REQUEST_NEWEST_ARTICLE_OF_PARTICULAR_DATE_DISPLAY_TITLE", @"Display title for a fetch request working against the latest article on a particular date");
	
	return fetchRequest;

}

- (NSFetchRequest *) newFetchRequestForArticlesOnDate:(NSDate*)date {
	NSCalendar *cal = [NSCalendar currentCalendar];
	
	NSDateComponents *dcomponents = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:date];
	[dcomponents setDay:[dcomponents day] + 1];
	NSDate *midnight = [cal dateFromComponents:dcomponents];
	
	dcomponents = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:date];
	NSDate *earlymorning = [cal dateFromComponents:dcomponents];
	
	NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRArticles" substitutionVariables:[NSDictionary dictionary]];
	
	fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:
																																							 
																																							 fetchRequest.predicate,
																																							 
																																							 [NSPredicate predicateWithFormat:@"creationDate >= %@ && creationDate <= %@", earlymorning, midnight],
																																							 
																																							 nil]];
	
	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO], nil];

	fetchRequest.relationshipKeyPathsForPrefetching = [NSArray arrayWithObjects:
																										 @"files",
																										 @"files.pageElements",
																										 @"previews",
																										 @"previews.graphElement",
																										 @"previews.graphElement.images",
																										 nil];
	
	fetchRequest.fetchBatchSize = 100;

	fetchRequest.displayTitle = NSLocalizedString(@"FETCH_REQUEST_ARTICLES_ON_PARTICULAR_DAY_DISPLAY_TITLE", @"Display title for a fetch request working against articles on a particular day");
	
	return fetchRequest;

}

- (NSFetchRequest *) newFetchRequestForArticlesWithPreviews {

	NSFetchRequest *fr = [self newFetchRequestForAllArticles];
	
	fr.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:
	
		fr.predicate,
		[NSPredicate predicateWithFormat:@"previews.@count > 0"],
	
	nil]];
	
	fr.displayTitle = NSLocalizedString(@"FETCH_REQUEST_ARTICLES_WITH_PREVIEWS_DISPLAY_TITLE", @"Display title for a fetch request working against the articles with Web Previews");
	
	return fr;

}

- (NSFetchRequest *) newFetchRequestForArticlesWithPhotos {

	NSFetchRequest *fr = [self newFetchRequestForAllArticles];
	
	fr.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[
									fr.predicate,
									[NSPredicate predicateWithFormat:@"files.@count > 0"],
									[NSPredicate predicateWithFormat:@"style == 0"]
									]];
	
	fr.displayTitle = NSLocalizedString(@"FETCH_REQUEST_ARTICLES_WITH_PHOTOS_DISPLAY_TITLE", @"Display title for a fetch request working against the articles with Photos");
	
	return fr;

}

- (NSFetchRequest *) newFetchRequestForArticlesWithoutPreviewsOrPhotos {

	NSFetchRequest *fr = [self newFetchRequestForAllArticles];
	
	fr.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:
	
		fr.predicate,
		[NSPredicate predicateWithFormat:@"previews.@count == 0"],
		[NSPredicate predicateWithFormat:@"files.@count == 0"],
	
	nil]];
	
	fr.displayTitle = NSLocalizedString(@"FETCH_REQUEST_ARTICLES_WITH_PLAIN_TEXT_DISPLAY_TITLE", @"Display title for a fetch request working against the articles with Plain Text");
	
	return fr;

}

- (NSFetchRequest *)newFetchRequestForUrlHistories {
	
	NSFetchRequest *fetch = [self newFetchRequestForAllArticles];
	fetch.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[
										 fetch.predicate,
										 [NSPredicate predicateWithFormat:@"style == %d", WAPostStyleURLHistory],
										 [NSPredicate predicateWithFormat:@"files.@count > 0"],
										 ]];
	fetch.displayTitle = NSLocalizedString(@"FETCH_REQUEST_URL_HISTORY",
																				 @"Caption for URL History");
										 
	return fetch;
}

- (NSFetchRequest *) newFetchRequestForFilesInArticle:(WAArticle *)article {

	NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRFilesForArticle" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
		article, @"Article",
	nil]];
	
	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
		[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES],
	nil];

	return fetchRequest;

}

- (void) fetchLatestCreatedArticleInGroup:(NSString *)aGroupIdentifier onSuccess:(void(^)(NSString *identifier, WAArticle *article))callback {

  [self fetchLatestCreatedArticleInGroup:aGroupIdentifier usingContext:[self disposableMOC] onSuccess:callback];

}

- (void) fetchLatestCreatedArticleInGroup:(NSString *)aGroupIdentifier usingContext:(NSManagedObjectContext *)context onSuccess:(void(^)(NSString *identifier, WAArticle *article))callback {

	NSParameterAssert(context);
  
  if (!callback)
    return;

  NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRArticles" substitutionVariables:[NSDictionary dictionary]];
  
  fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
//    [NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:NO],
    [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO],
  nil];
  
  fetchRequest.fetchLimit = 1;
  
  NSError *fetchingError = nil;
  NSArray *fetchedArticles = [context executeFetchRequest:fetchRequest error:&fetchingError];
  
  if (!fetchedArticles) {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, fetchingError);
    callback(nil, nil);
    return;
  }
  
  WAArticle *fetchedArticle = [fetchedArticles lastObject];
  callback(fetchedArticle.identifier, fetchedArticle);

}

- (void) fetchArticleWithIdentifier:(NSString *)anArticleIdentifier usingContext:(NSManagedObjectContext *)aContext onSuccess:(void(^)(NSString *identifier, WAArticle *article))callback {

  if (!callback)
    return;
	
	if (!anArticleIdentifier) {
		if (callback)
			callback(nil, nil);
		return;
	}

  NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRArticle" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
  
    anArticleIdentifier, @"Identifier",
  
  nil]];
  
  fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
    [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO],
  nil];
  
  fetchRequest.fetchLimit = 1;
  
  NSError *fetchingError = nil;
  NSArray *fetchedArticles = [aContext executeFetchRequest:fetchRequest error:&fetchingError];
  
  if (![fetchedArticles count]) {
    callback(nil, nil);
    return;
  }
  
  WAArticle *fetchedArticle = [fetchedArticles objectAtIndex:0];
  callback(fetchedArticle.identifier, fetchedArticle);  

}

- (NSArray *) fetchFilesNeedingDownloadUsingContext:(NSManagedObjectContext *)aContext {

	NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRFilesNeedingDownload" substitutionVariables:[NSDictionary dictionary]];

	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
		[NSSortDescriptor sortDescriptorWithKey:@"article.creationDate" ascending:YES],
	nil];

	NSError *fetchingError = nil;
	NSArray *fetchedFiles = [aContext executeFetchRequest:fetchRequest error:&fetchingError];
	if (fetchingError) {
		NSLog(@"%@", fetchingError);
	}
	return fetchedFiles;

}

- (WAArticle *)fetchLatestLocalImportedArticleUsingContext:(NSManagedObjectContext *)aContext {

	NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRLocalImportedArticles" substitutionVariables:[NSDictionary dictionary]];
	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
																	[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO],
																	nil];
	fetchRequest.fetchLimit = 1;

	NSError *fetchingError = nil;
	NSArray *fetchedArticles = [aContext executeFetchRequest:fetchRequest error:&fetchingError];
	if (fetchingError) {
		NSLog(@"%@", fetchingError);
		return nil;
	}

	return [fetchedArticles lastObject];

}

- (NSArray *)fetchAllFilesUsingContext:(NSManagedObjectContext *)aContext {

	NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRAllFiles" substitutionVariables:@{}];
	
	NSError *fetchingError = nil;
	NSArray *fetchedFiles = [aContext executeFetchRequest:fetchRequest error:&fetchingError];
	if (fetchingError) {
		NSLog(@"%@", fetchingError);
		return nil;
	}
	
	return fetchedFiles;

}

- (NSArray *)fetchAllOGImagesUsingContext:(NSManagedObjectContext *)aContext {

	NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRAllOGImages" substitutionVariables:@{}];
	
	NSError *fetchingError = nil;
	NSArray *fetchedOGImages = [aContext executeFetchRequest:fetchRequest error:&fetchingError];
	if (fetchingError) {
		NSLog(@"%@", fetchingError);
		return nil;
	}
	
	return fetchedOGImages;

}

@end
