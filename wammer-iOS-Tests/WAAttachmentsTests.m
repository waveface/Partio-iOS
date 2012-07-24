//
//  WAAttachmentsTests.m
//  wammer
//
//  Created by jamie on 7/24/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAAttachmentsTests.h"
#import "WADataStore.h"
#import "WAArticle.h"

@implementation WAAttachmentsTests {
	NSManagedObjectContext *context;
	NSArray *changedArticleReps;
}

- (void)setUp {
	context = [[WADataStore defaultStore] disposableMOC];
	
	NSString *filePath = [[NSBundle bundleForClass:[self class]]
												pathForResource:@"PostWithIncompleteAttachmentInformation"
												ofType:@"txt"];
	
	NSData *inputData = [NSData dataWithContentsOfFile:filePath];
	changedArticleReps = [NSJSONSerialization
												 JSONObjectWithData:inputData
												 options:NSJSONReadingMutableContainers
												 error:nil];
}

- (void)tearDown {
	context = nil;
	changedArticleReps = nil;
}

- (void)testChangedArticleShouldBeParsedCorrectly {
	STAssertNotNil(changedArticleReps, @"should be a JSON array");
	NSArray *touchedArticles = [WAArticle
															insertOrUpdateObjectsUsingContext:context
															withRemoteResponse:changedArticleReps
															usingMapping:nil
															options:IRManagedObjectOptionIndividualOperations];
	
	for (WAArticle *article in touchedArticles) {
		[context refreshObject:article mergeChanges:NO];
	}
	
	[context save:nil];
}
@end
