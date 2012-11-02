//
//  WACollectionTests.m
//  wammer
//
//  Created by jamie on 12/11/2.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WACollectionTests.h"
#import "CoreData+MagicalRecord.h"
#import "WAArticle.h"
#import "WAUser.h"

@implementation WACollectionTests

- (void)setUp {
	[MagicalRecord setDefaultModelFromClass:[self class]];
	[MagicalRecord setupCoreDataStackWithInMemoryStore];
}

- (void)tearDown {
	[MagicalRecord cleanUp];
}

- (void)testSometingReallySimple {
	WAArticle *testArticle = [WAArticle MR_createEntity];
	STAssertNotNil(testArticle, @"Should not be nil");
	
	testArticle.text = @"Some text here";
	testArticle.owner = [WAUser MR_createEntity];
	NSArray *arrayOfArticles = [WAArticle MR_findAll];
	STAssertEquals(@"Some text here", ((WAArticle *) arrayOfArticles[0]).text,
								 @"Should be the same.");
}

- (void)testFindAll {
}
@end
