//
//  WACollectionTests.m
//  wammer
//
//  Created by jamie on 12/11/2.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WACollectionTests.h"
#import "CoreData+MagicalRecord.h"
#import "WACollection.h"
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
	WACollection *collection = [WACollection MR_createEntity];
	STAssertNotNil(collection, @"Should not be nil");
	
	collection.creator = [WAUser MR_createEntity];
	collection.createDate = [NSDate date];
	collection.title = @"This should be collection title";
	NSArray *collections = [WACollection MR_findAll];
	STAssertEquals(collection.title, ((WACollection *) collections[0]).title,
								 @"Should be the same.");
}

- (void)testFindAll {
}
@end
