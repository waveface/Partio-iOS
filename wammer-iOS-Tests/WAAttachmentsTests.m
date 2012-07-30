//
//  WAAttachmentsTests.m
//  wammer
//
//  Created by jamie on 7/24/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAAttachmentsTests.h"
#import "WADataStore.h"
#import "WADataStore+FetchingConveniences.h"
#import "WAArticle.h"

@implementation WAAttachmentsTests {
	NSManagedObjectContext *context;
}

- (NSArray *)loadDataFile: (NSString *)fileString {
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
	STAssertTrue([article.files count] == 20, @"attachments should be decorated to 20");
	
	NSFetchRequest *fetchRequest = [[WADataStore defaultStore] newFetchRequestForFilesInArticle:article];
	
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc]
																													initWithFetchRequest:fetchRequest
																													managedObjectContext:article.managedObjectContext
																													sectionNameKeyPath:nil
																													cacheName:nil];
	NSError *fetchError = nil;
	if (![fetchedResultsController performFetch:&fetchError])
		NSLog(@"Error fetching: %@", fetchError);
	
	STAssertTrue([[fetchedResultsController fetchedObjects]count] == 20, @"should be 20");
	
	[context refreshObject:article mergeChanges:NO];
	[context save:nil];
	
	
}

- (void)testArticleWithFullInformation {
	NSArray *articleReps = [self loadDataFile:@"PostWithCompleteAttachmentInformation"];
	STAssertNotNil(articleReps, @"need to be a vaild JSON");
	NSArray *trasnformedArticle = [WAArticle
																 insertOrUpdateObjectsUsingContext:context
																 withRemoteResponse:articleReps
																 usingMapping:nil
																 options:IRManagedObjectOptionIndividualOperations];
	WAArticle *article = [trasnformedArticle objectAtIndex:0];
	STAssertTrue([article.files count] == 4, @"");
}
@end
