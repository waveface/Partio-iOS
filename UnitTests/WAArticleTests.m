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

- (void)testArticleWithEventTimeInAttachment {
	NSArray *articleReps = [self loadDataFile:@"PostWithEventTime"];
	NSArray *transformed = [WAArticle
													insertOrUpdateObjectsUsingContext:context
													withRemoteResponse:articleReps
													usingMapping:nil
													options:IRManagedObjectOptionIndividualOperations];
	WAArticle *article = [transformed objectAtIndex:0];
	for (WAFile* photo in article.files) {
		assertThat(photo.eventTime, notNilValue());
		assertThat(photo.eventTime, instanceOf([NSDate class]));
	}
}
@end
