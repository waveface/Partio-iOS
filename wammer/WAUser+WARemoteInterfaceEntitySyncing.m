//
//  WAUser+WARemoteEntitySyncing.m
//  wammer
//
//  Created by Evadne Wu on 4/19/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAUser+WARemoteInterfaceEntitySyncing.h"
#import "WARemoteInterfaceEntitySyncing.h"
#import "IRWebAPIKit.h"

@implementation WAUser (WARemoteInterfaceEntitySyncing)

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
  @"storages": @"WAStorage",
  @"groups": @"WAGroup",
  @"stations": @"WAStation"
  };
  
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {
  
  static NSDictionary *mapping = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    
    mapping = @{
    @"avatar_url": @"avatarURL",
    @"user_id": @"identifier",
    @"nickname": @"nickname",
    @"email": @"email",
    @"storages": @"storages",
    @"groups": @"groups",
    @"stations": @"stations"
    };
    
  });
  
  return mapping;
  
}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {
  
  NSDictionary *storages = [incomingRepresentation valueForKey:@"storages"];
  if (!storages)
    return incomingRepresentation;
  
  NSMutableDictionary *massagedRep = [incomingRepresentation mutableCopy];
  NSArray *massagedStorageReps = [[storages allKeys] irMap:^(NSString *displayName, NSUInteger index, BOOL *stop) {
    
    NSMutableDictionary *entity = [[storages objectForKey:displayName] mutableCopy];
    [entity setObject:displayName forKey:@"display_name"];
    return entity;
    
  }];
  
  [massagedRep setObject:massagedStorageReps forKey:@"storages"];
  
  return massagedRep;
  
}

- (void) configureWithRemoteDictionary:(NSDictionary *)inDictionary {
  
  [super configureWithRemoteDictionary:inDictionary];
  
}

+ (id) transformedValue:(id)aValue fromRemoteKeyPath:(NSString *)aRemoteKeyPath toLocalKeyPath:(NSString *)aLocalKeyPath {
  
  if ([aLocalKeyPath isEqualToString:@"identifier"])
    return IRWebAPIKitStringValue(aValue);
  
  return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];
  
}

@end
