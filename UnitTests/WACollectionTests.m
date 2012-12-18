//
//  WACollectionTests.m
//  wammer
//
//  Created by jamie on 12/11/2.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WACollectionTests.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "WACollection+WARemoteInterfaceEntitySyncing.h"
#import "WAUser.h"
#import "WAFile.h"

@implementation WACollectionTests

- (id)loadDataFile: (NSString *)fileString {
  NSString *filePath = [[NSBundle bundleForClass:[self class]]
		    pathForResource:fileString
		    ofType:@"json"];
  
  NSData *inputData = [NSData dataWithContentsOfFile:filePath];
  return [NSJSONSerialization
	JSONObjectWithData:inputData
	options:nil
	error:nil];
}

- (void)setUp {
  [MagicalRecord setDefaultModelFromClass:[self class]];
  [MagicalRecord setupCoreDataStackWithInMemoryStore];
}

- (void)tearDown {
  [MagicalRecord cleanUp];
}

- (void)testSomethingReallySimple {
  WACollection *collection = [WACollection MR_createEntity];
  STAssertNotNil(collection, @"Should not be nil");
  
  collection.creationDate = [NSDate distantPast];
  collection.modificationDate = [NSDate date];
  collection.title = @"This should be collection title";
  collection.creator = [WAUser MR_createEntity];
  NSArray *collections = [WACollection MR_findAll];
  STAssertEquals(collection.title, ((WACollection *) collections[0]).title,
	       @"Should be the same.");
  
  WAFile *photo1 = [WAFile MR_createEntity];
  photo1.thumbnailURL = @"URL1";
  WAFile *photo2 = [WAFile MR_createEntity];
  photo2.thumbnailURL = @"URL2";
  collection.files = [NSOrderedSet orderedSetWithArray:@[photo1, photo2]];
  NSOrderedSet *photos = ((WACollection *) collections[0]).files;
  STAssertEqualObjects(@"URL1", ((WAFile*)photos[0]).thumbnailURL,
		   @"Thumbnail URL persistent");
}

- (void)testGetSingleCollection {
  NSDictionary *collectionsRep = [self loadDataFile:@"GetCollections"];
  STAssertNotNil(collectionsRep, @"need to be a vaild JSON");
  
  NSArray *collections = [collectionsRep objectForKey:@"collections"];
  
  NSArray *transformed;
  @autoreleasepool {
    transformed = [WACollection
	         insertOrUpdateObjectsUsingContext:[NSManagedObjectContext MR_context]
	         withRemoteResponse:collections
	         usingMapping:nil
	         options:IRManagedObjectOptionIndividualOperations];
  }
  
  NSUInteger touches = 0;
  for (WACollection *coll in transformed) {
    STAssertNotNil(coll.identifier, @"identifier should not be nil");
    if ([coll.identifier isEqualToString:@"441d03ce-dc01-4029-bcfe-4be8853396f6"]) {
      assertThat(coll.isHidden, equalTo(@(0)));
      assertThat(coll.isSmart, equalTo(@(0)));
      assertThat(coll.sequenceNumber, equalTo(@(35680)));
      assertThat(coll.title, equalTo(@"Food"));
      STAssertEquals([coll.files count], (NSUInteger)8, @"With Object IDs");
      touches ++;
    }
    if ([coll.identifier isEqualToString:@"0bc1d4ce-bbf3-49c0-a5fe-d454b96493a0"]) {
      assertThat(coll.isHidden, equalTo(@(1)));
      touches ++;
    }
  }
  
  STAssertTrue(touches == 2, @"These two instances must be touched");
}

@end
