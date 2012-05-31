//
//  WADataStoreTest.m
//  wammer
//
//  Created by Evadne Wu on 3/26/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADataStoreTest.h"
#import "WADataStore.h"
#import "Foundation+IRAdditions.h"

@implementation WADataStoreTest

- (WAArticle *) disposableArticleWithContext:(NSManagedObjectContext **)outContext {

	WADataStore *ds = [WADataStore defaultStore];
	NSManagedObjectContext *context = [ds disposableMOC];
	WAArticle *article = [WAArticle objectInsertingIntoContext:context withRemoteDictionary:nil];

	STAssertNotNil(article, @"Article must instantiate correctly");
	
	if (outContext)
		*outContext = context;
	
	return article;

}

- (WAFile *) newFileInContext:(NSManagedObjectContext *)context {

	return [WAFile objectInsertingIntoContext:context withRemoteDictionary:[NSDictionary dictionaryWithObjectsAndKeys:IRDataStoreNonce(), @"identifier", nil]];

}

- (void) testRepresentingFile {

	NSManagedObjectContext *context = nil;
	WAArticle *article = [self disposableArticleWithContext:&context];
	STAssertNil(article.representingFile, @"Article %@ should not have a representing file when created");

	WAFile *file1 = [self newFileInContext:context];
	[[article mutableOrderedSetValueForKey:@"files"] addObject:file1];
	
	WAFile *file2 = [self newFileInContext:context];
	[[article mutableOrderedSetValueForKey:@"files"] addObject:file2];
	
	STAssertEqualObjects(file1, article.representingFile, @"Article should use the first file in the files array as an implicit represented file");
	
	WAFile *file3 = [self newFileInContext:context];
	article.representingFile = file3;
	
	STAssertTrue([article.files containsObject:file3], @"Associating a representing file should implicitly add it to the article");
	
	[[article mutableOrderedSetValueForKey:@"files"] removeObject:file2];
	
	STAssertEqualObjects([article.files objectAtIndex:0], article.representingFile, @"Removing a representing file from the article’s file collection should revert the implicit representing file to the first one in files");
	
}

@end
