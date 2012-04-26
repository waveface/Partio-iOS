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

- (void) assertFileEquivalancy:(WAArticle *)article {

	NSSet *files = article.files;
	
	STAssertEquals([files count], [article.fileOrder count], @"Number of files in the backing array must equal the number of files in the unordered to-many relationship.");

	NSSet *fileIDs = [article.files irMap: ^ (NSManagedObject *obj, BOOL *stop) {
		return [[obj objectID] URIRepresentation];
	}];
	
	NSSet *orderedFileIDs = [NSSet setWithArray:article.fileOrder];
	
	STAssertEqualObjects(fileIDs, orderedFileIDs, @"Number of files in the backing array must equal the number of files in the unordered to-many relationship.");

}

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

- (void) testOrderedRelationshipMutationFromSet {

	NSManagedObjectContext *context = nil;
	WAArticle *article = [self disposableArticleWithContext:&context];
	
	WAFile *file = [self newFileInContext:context];
	[article addFilesObject:file];
	[self assertFileEquivalancy:article];
	
	STAssertTrue([article.fileOrder containsObject:[[file objectID] URIRepresentation]], @"After inserting an entity to the unordered to-many relationship,  the object ID should show up in the backing order array");
	
	WAFile *secondFile = [self newFileInContext:context];
	[article addFilesObject:secondFile];
	[self assertFileEquivalancy:article];

	STAssertTrue([article.fileOrder containsObject:[[file objectID] URIRepresentation]], @"After inserting an entity to the unordered to-many relationship,  the object ID should show up in the backing order array");
	STAssertTrue([article.fileOrder containsObject:[[secondFile objectID] URIRepresentation]], @"After inserting an entity to the unordered to-many relationship,  the object ID should show up in the backing order array");

}

- (void) testOrderedRelationshipMutationFromArray {

	NSManagedObjectContext *context = nil;
	WAArticle *article = [self disposableArticleWithContext:&context];
	
	WAFile *file = [self newFileInContext:context];
	[file.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:file] error:nil];
	NSMutableArray *newOrder = [article.fileOrder mutableCopy];
	[newOrder addObject:[[file objectID] URIRepresentation]];
	article.fileOrder = newOrder;
	[self assertFileEquivalancy:article];
	
	STAssertTrue([article.files containsObject:file], @"After inserting an entity to the unordered to-many relationship,  the object ID should show up in the backing order array.");
	
	WAFile *secondFile = [self newFileInContext:context];
	[secondFile.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:secondFile] error:nil];
	NSMutableArray *nextOrder = [article.fileOrder mutableCopy];
	[nextOrder addObject:[[secondFile objectID] URIRepresentation]];
	article.fileOrder = nextOrder;
	[self assertFileEquivalancy:article];
	
	STAssertTrue([article.files containsObject:file], @"After inserting an entity to the unordered to-many relationship,  the object ID should show up in the backing order array.");
	STAssertTrue([article.files containsObject:secondFile], @"After inserting an entity to the unordered to-many relationship,  the object ID should show up in the backing order array.");

}

- (void) testRepresentingFile {

	NSManagedObjectContext *context = nil;
	WAArticle *article = [self disposableArticleWithContext:&context];
	STAssertNil(article.representingFile, @"Article %@ should not have a representing file when created");

	WAFile *file1 = [self newFileInContext:context];
	[article addFilesObject:file1];
	
	WAFile *file2 = [self newFileInContext:context];
	[article addFilesObject:file2];
	
	STAssertEqualObjects(file1, article.representingFile, @"Article should use the first file in the files array as an implicit represented file");
	
	WAFile *file3 = [self newFileInContext:context];
	article.representingFile = file3;
	
	STAssertTrue([article.files containsObject:file3], @"Associating a representing file should implicitly add it to the article");
	
	[article removeFilesObject:file3];
	
	STAssertEqualObjects([article irObjectAtIndex:0 inArrayKeyed:@"fileOrder"], article.representingFile, @"Removing a representing file from the article’s file collection should revert the implicit representing file to the first one in fileOrder");
	
}

@end
