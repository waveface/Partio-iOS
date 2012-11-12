//
//  WAAttachmentsTests.m
//
//  Created by jamie on 7/24/12.
//  Copyright (c) 2012 Waveface Inc. All rights reserved.
//

#import "WAArticleTests.h"
#import "WADataStore.h"
#import "WADataStore+FetchingConveniences.h"
#import "WAArticle.h"

@implementation WAArticleTests {
	NSManagedObjectContext *context;
}

- (id)loadDataFile: (NSString *)fileString {
	NSString *filePath = [[NSBundle bundleForClass:[self class]]
												pathForResource:fileString
												ofType:@"txt"];
	
	NSData *inputData = [NSData dataWithContentsOfFile:filePath];
	return [NSJSONSerialization
					JSONObjectWithData:inputData
					options:NSJSONReadingMutableContainers
					error:nil];
}

- (void)setUp {
	context = [[WADataStore defaultStore] disposableMOC];
	
}

- (void)tearDown {
	context = nil;
}

- (void)testArticleWithIncompletedAttachmentShouldBeDecorated {
	NSArray *changedArticleReps = [self loadDataFile:@"PostWithIncompleteAttachmentInformation"];
	STAssertNotNil(changedArticleReps, @"should be a JSON array");
	
	NSArray *touchedArticles = [WAArticle
															insertOrUpdateObjectsUsingContext:context
															withRemoteResponse:changedArticleReps
															usingMapping:nil
															options:IRManagedObjectOptionIndividualOperations];
	
	WAArticle *article = [touchedArticles objectAtIndex:0];
	
	STAssertEquals((NSUInteger)20, [article.files count],
								 @"attachments should be decorated to 20");
	
	NSFetchRequest *fetchRequest = [[WADataStore defaultStore] newFetchRequestForFilesInArticle:article];
	
	NSFetchedResultsController *fetchedResultsController =
	[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																			managedObjectContext:article.managedObjectContext
																				sectionNameKeyPath:nil
																								 cacheName:nil];
	NSError *fetchError = nil;
	if (![fetchedResultsController performFetch:&fetchError])
		NSLog(@"Error fetching: %@", fetchError);
	
	STAssertEquals((NSUInteger)20, [[fetchedResultsController fetchedObjects] count],
								 @"Should be 20.");
	
	for (WAFile *photo in [fetchedResultsController fetchedObjects]) {
		STAssertEqualObjects(@"public.jpeg", photo.resourceType, @"Type must be jpeg.");
		STAssertEqualObjects(@"image", photo.remoteResourceType, @"Must be an image.");
		STAssertNotNil(photo.smallThumbnailURL, @"Small thumbnail required");
		STAssertNotNil(photo.thumbnailURL, @"Medium thumbnail required");
	}
}

- (void)testArticleWithFullInformation {
	NSArray *articleReps = [self loadDataFile:@"PostWithCompleteAttachmentInformation"];
	STAssertNotNil(articleReps, @"need to be a vaild JSON");
	NSArray *transformed = [WAArticle insertOrUpdateObjectsUsingContext:context
																									 withRemoteResponse:articleReps
																												 usingMapping:nil
																															options:IRManagedObjectOptionIndividualOperations];
	WAArticle *article = [transformed objectAtIndex:0];
	STAssertEquals((NSUInteger)4, [article.files count],
								 @"This post should have 4 attachments");
}

- (void)testArticleWithURLHistoryStyle {
	NSArray *articleReps = [self loadDataFile:@"PhotoPostWithURLHistoryStyle"];
	NSArray *transformed = [WAArticle insertOrUpdateObjectsUsingContext:context
																									 withRemoteResponse:articleReps
																												 usingMapping:nil
																															options:IRManagedObjectOptionIndividualOperations];
	WAArticle *article = [transformed objectAtIndex:0];
	STAssertTrue(WAPostStyleURLHistory == article.style.intValue , @"Style should be URL History");
}
@end
