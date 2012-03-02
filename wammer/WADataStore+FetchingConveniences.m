//
//  WADataStore+FetchingConveniences.m
//  wammer
//
//  Created by Evadne Wu on 12/14/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADataStore+FetchingConveniences.h"

@implementation WADataStore (FetchingConveniences)

- (NSFetchRequest *) newFetchRequestForAllArticles {

	NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRArticles" substitutionVariables:[NSDictionary dictionary]];
	
	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
		[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO],
	nil];
	
	fetchRequest.relationshipKeyPathsForPrefetching = [NSArray arrayWithObjects:
		@"files",
		@"files.pageElements",
		@"previews",
		@"previews.graphElement",
		@"previews.graphElement.images",
	nil];
	
	fetchRequest.fetchBatchSize = 20;
	
	return [fetchRequest retain];

}

- (void) fetchLatestArticleInGroup:(NSString *)aGroupIdentifier onSuccess:(void(^)(NSString *identifier, WAArticle *article))callback {

  [self fetchLatestArticleInGroup:aGroupIdentifier usingContext:[self disposableMOC] onSuccess:callback];

}

- (void) fetchLatestArticleInGroup:(NSString *)aGroupIdentifier usingContext:(NSManagedObjectContext *)context onSuccess:(void(^)(NSString *identifier, WAArticle *article))callback {
  
  if (!callback)
    return;

  NSFetchRequest *fetchRequest = [self.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRArticles" substitutionVariables:[NSDictionary dictionary]];
  
  fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
    [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO],
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
    [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO],
  nil];
  
  fetchRequest.fetchLimit = 1;
  
  NSError *fetchingError = nil;
  NSArray *fetchedArticles = [aContext executeFetchRequest:fetchRequest error:&fetchingError];
  
  if (![fetchedArticles count]) {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, fetchingError);
    callback(nil, nil);
    return;
  }
  
  WAArticle *fetchedArticle = [fetchedArticles objectAtIndex:0];
  callback(fetchedArticle.identifier, fetchedArticle);  

}

@end
