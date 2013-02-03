//
//  WACollection+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by jamie on 12/11/27.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WACollection+WARemoteInterfaceEntitySyncing.h"
#import "IRWebAPIKit.h"
#import <SSToolkit/NSDate+SSToolkitAdditions.h>

@implementation WACollection (WARemoteInterfaceEntitySyncing)

+ (NSString *) keyPathHoldingUniqueValue {
  
  return @"identifier";
  
}

+ (BOOL) skipsNonexistantRemoteKey {
  
  //	Allows piecemeal data patching, by skipping code path that assigns a placeholder value for any missing value
  //	that -configureWithRemoteDictionary: gets
  return YES;
  
}

+ (NSDictionary *) defaultHierarchicalEntityMapping {
  
  return @{
  @"files": @"WAFile",
  @"creator": @"WAUser",
  @"cover": @"WAFile",
  };
  
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {
  
  static NSDictionary *mapping = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    
    mapping = @{
    @"name": @"title",
    @"seq_num": @"sequenceNumber",
    @"files": @"files",
    @"creator": @"creator",
    @"create_time": @"creationDate",
    @"modify_time": @"modificationDate",
    @"collection_id": @"identifier",
    @"hidden": @"isHidden",
    @"smart": @"isSmart",
    @"cover": @"cover",
    };
    
  });
  
  return mapping;
  
}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingDictionary {
  NSMutableDictionary *returnedDictionary = [incomingDictionary mutableCopy];
  
  NSString *creatorID = incomingDictionary[@"creator_id"];
  if ([creatorID length])
    returnedDictionary[@"creator"] = @{@"user_id": creatorID};
  
  returnedDictionary[@"files"] = incomingDictionary[@"object_list"];
  
  NSString *collectionCover = incomingDictionary[@"cover"];
  if ([collectionCover length]){
    returnedDictionary[@"cover"] = @{@"object_id": collectionCover};
	} else {
		[returnedDictionary removeObjectForKey:@"cover"];
		NSLog(@"Collection %@: cover is wrong.", incomingDictionary[@"collection_id"]);
	}
  
  return returnedDictionary;
}

+ (id) transformedValue:(id)aValue
      fromRemoteKeyPath:(NSString *)aRemoteKeyPath
         toLocalKeyPath:(NSString *)aLocalKeyPath {
  
  if ([aLocalKeyPath isEqualToString:@"modificationDate"] ||
      [aLocalKeyPath isEqualToString:@"creationDate"] )
    return [NSDate dateFromISO8601String:aValue];
  
  return [super transformedValue:aValue
	     fromRemoteKeyPath:aRemoteKeyPath
	        toLocalKeyPath:aLocalKeyPath];
  
}

+ (void)synchronizeWithOptions:(NSDictionary *)options completion:(WAEntitySyncCallback)completionBlock {
  
}

+ (void)synchronizeWithCompletion:(WAEntitySyncCallback)block {
  
}

- (void)synchronizeWithCompletion:(WAEntitySyncCallback)block {
  [self synchronizeWithOptions:nil completion:block];
}

- (void)synchronizeWithOptions:(NSDictionary *)options completion:(WAEntitySyncCallback)completionBlock {
  
}



@end

