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
#import "WACollection+RemoteOperations.h"
#import <OCMock/OCMock.h>
#import "WARemoteInterface.h"

@implementation WACollectionTests

- (id)loadDataFile: (NSString *)fileString {
  NSString *filePath = [[NSBundle bundleForClass:[self class]]
                        pathForResource:fileString
                        ofType:@"json"];
  
  NSData *inputData = [NSData dataWithContentsOfFile:filePath];
  return [NSJSONSerialization
          JSONObjectWithData:inputData
          options:(NSJSONReadingOptions)0
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
  NSDictionary *collectionsResponse = [self loadDataFile:@"GetCollections"];
  STAssertNotNil(collectionsResponse, @"need to be a vaild JSON");
  
  NSArray *transformed;
  @autoreleasepool {
    transformed = [WACollection
                   insertOrUpdateObjectsUsingContext:[NSManagedObjectContext MR_context]
                   withRemoteResponse:[collectionsResponse objectForKey:@"collections"]
                   usingMapping:nil
                   options:IRManagedObjectOptionIndividualOperations];
  }
  
  NSUInteger touches = 0;
  for (WACollection *collection in transformed) {
    STAssertNotNil(collection.identifier, @"identifier should not be nil");
    //replace OCHamcrest Collection style
    if ([collection.identifier isEqualToString:@"441d03ce-dc01-4029-bcfe-4be8853396f6"]) {
      assertThat(collection.isHidden, equalTo(@(0)));
      assertThat(collection.isSmart, equalTo(@(0)));
      assertThat(collection.sequenceNumber, equalTo(@(35680)));
      assertThat(collection.title, equalTo(@"Food"));
      assertThat(collection.cover.identifier, equalTo(@"aabe6dc8-6d2a-4e78-90e9-2bec081aa79f"));
      STAssertEquals([collection.files count], (NSUInteger)8, @"With Object IDs");
      touches ++;
    }
    if ([collection.identifier isEqualToString:@"0bc1d4ce-bbf3-49c0-a5fe-d454b96493a0"]) {
      assertThat(collection.isHidden, equalTo(@(1)));
      touches ++;
    }
  }
  
  STAssertTrue(touches == 2, @"These two instances must be touched");
  
}

- (void)testCreateAnEmptyCollection {
  WACollection *newCollection = [[WACollection alloc] initWithName: @"Empty"
                                                        withFiles: @[]
                                            inManagedObjectContext:[NSManagedObjectContext MR_context]];
  STAssertNil(newCollection, @"Should fail.");
}

- (void)testMaxSequenceNumber {
  WADataStore *dataStore = [WADataStore defaultStore];
  [dataStore setMaxSequenceNumber:@100];
  [dataStore setMaxSequenceNumber:@50];
  assertThat([dataStore maxSequenceNumber], equalTo(@100));
}
  
- (void)testMaxSequenceNumberWithDefaultSetterAndGetter {
  WADataStore *dataStore = [WADataStore defaultStore];
  dataStore.maxSequenceNumber = @100;
  dataStore.maxSequenceNumber = @50;
  assertThat(dataStore.maxSequenceNumber, equalTo(@100));
}

//- (void)testCreateACollectionWith2Files {
//  NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
//  NSArray *objectIDs = @[[WAFile MR_createInContext:context],[WAFile MR_createInContext:context]];
//  
//  WACollection *collection = [[WACollection alloc] initWithName:@"Memories"
//                                                      withFiles:objectIDs
//                                         inManagedObjectContext:context];
//  
//  assertThat(collection.title, equalTo(@"Memories"));
//  STAssertEquals([collection.files count], (NSUInteger)2, @"There should be two objcets");
//  STAssertNotNil(collection.identifier, @"UUID generated");
//  assertThat(collection.isHidden, equalTo(@0));
//}

@end
