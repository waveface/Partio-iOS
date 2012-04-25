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
	
	fetchRequest.fetchBatchSize = 20;
	
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

- (NSFetchRequest *) newFetchRequestForNewestArticle {

	NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRArticles" substitutionVariables:[NSDictionary dictionary]];
	
	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
    [NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:NO],
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
	
	NSDate *datum = [date dateByAddingTimeInterval:86400];
	
	fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:
	
		fetchRequest.predicate,
	
		[NSPredicate predicateWithFormat:@"((modificationDate == nil) AND (creationDate <= %@)) OR (modificationDate <= %@)", datum, datum],
	
	nil]];
	
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
	
	fetchRequest.fetchBatchSize = 1;
	fetchRequest.fetchLimit = 1;
	
	fetchRequest.displayTitle = NSLocalizedString(@"FETCH_REQUEST_NEWEST_ARTICLE_OF_PARTICULAR_DATE_DISPLAY_TITLE", @"Display title for a fetch request working against the latest article on a particular date");
	
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
	
	fr.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:
	
		fr.predicate,
		[NSPredicate predicateWithFormat:@"files.@count > 0"],
	
	nil]];
	
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

- (NSFetchRequest *) newFetchRequestForFilesInArticle:(WAArticle *)article {

	NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRImagesForArticle" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
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

@end
