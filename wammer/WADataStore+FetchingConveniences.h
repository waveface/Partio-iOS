//
//  WADataStore+FetchingConveniences.h
//  wammer
//
//  Created by Evadne Wu on 12/14/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADataStore.h"
#import "WACache.h"

@class WAArticle;

@interface WADataStore (FetchingConveniences)

- (NSFetchRequest *) newFetchRequestForUsersWithIdentifier:(NSString *)identifier;

- (NSFetchRequest *) newFetchRequestForAllArticles NS_RETURNS_RETAINED;
- (NSFetchRequest *) newFetchRequestForFilesInArticle:(WAArticle *)article;

- (NSFetchRequest *) newFetchRequestForOldestArticle;
- (NSFetchRequest *) newFetchRequestForOldestArticleAfterDate:(NSDate*)date;
- (NSFetchRequest *) newFetchRequestForNewestArticle;
- (NSFetchRequest *) newFetchRequestForNewestArticleOnDate:(NSDate *)date;
- (NSFetchRequest *) newFetchRequestForArticlesOnDate:(NSDate*)date;

- (NSFetchRequest *) newFetchRequestForArticlesWithPreviews;
- (NSFetchRequest *) newFetchRequestForArticlesWithPhotos;
- (NSFetchRequest *) newFetchRequestForArticlesWithoutPreviewsOrPhotos;
- (NSFetchRequest *) newFetchRequestForUrlHistories;

- (void) fetchLatestCreatedArticleInGroup:(NSString *)aGroupIdentifier onSuccess:(void(^)(NSString *identifier, WAArticle *article))callback;

- (void) fetchLatestCreatedArticleInGroup:(NSString *)aGroupIdentifier usingContext:(NSManagedObjectContext *)aContext onSuccess:(void(^)(NSString *identifier, WAArticle *article))callback;

- (void) fetchArticleWithIdentifier:(NSString *)anArticleIdentifier usingContext:(NSManagedObjectContext *)aContext onSuccess:(void(^)(NSString *identifier, WAArticle *article))callback;

- (NSArray *) fetchFilesNeedingDownloadUsingContext:(NSManagedObjectContext *)aContext;

- (WAArticle *) fetchLatestLocalImportedArticleUsingContext:(NSManagedObjectContext *)aContext;

- (NSArray *) fetchAllFilesUsingContext:(NSManagedObjectContext *)aContext;
- (NSArray *) fetchAllOGImagesUsingContext:(NSManagedObjectContext *)aContext;
- (NSArray *) fetchAllCachesUsingContext:(NSManagedObjectContext *)aContext;
- (NSNumber *) fetchTotalCacheSizeUsingContext:(NSManagedObjectContext *)aContext;
- (WACache *) fetchCacheWithPredicate:(NSPredicate *)aPredicate usingContext:(NSManagedObjectContext *)aContext;
- (NSArray *) fetchFilesWithoutMetaUsingContext:(NSManagedObjectContext *)aContext;

@end
