//
//  WACheckin+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Shen Steven on 4/7/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WACheckin+WARemoteInterfaceEntitySyncing.h"

@implementation WACheckin (WARemoteInterfaceEntitySyncing)

+ (NSString *) keyPathHoldingUniqueValue {
  
  return @"identifier";
  
}

+ (BOOL) skipsNonexistantRemoteKey {
  
  //	Allows piecemeal data patching, by skipping code path that assigns a placeholder value for any missing value
  //	that -configureWithRemoteDictionary: gets
  return YES;
  
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {
  
  static NSDictionary *mapping = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    
    mapping = @{
                @"name": @"name",
                @"message": @"message",
                @"identifier": @"identifier",
                @"create_time": @"createDate",
                @"tagged_uids": @"taggedUsers"
                };
    
  });
  
  return mapping;
  
}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingDictionary {
  NSMutableDictionary *returnedDictionary = [incomingDictionary mutableCopy];
  
  NSNumber *timestampNumber = incomingDictionary[@"timestamp"];
  if (timestampNumber) {
    returnedDictionary[@"create_time"] = [NSDate dateWithTimeIntervalSince1970:timestampNumber.intValue];
  }
  
  NSNumber *checkinID = incomingDictionary[@"checkin_id"];
  if (checkinID) {
    returnedDictionary[@"identifier"] = [NSString stringWithFormat:@"%@", checkinID];
  }
    
  return returnedDictionary;
}

+ (id) transformedValue:(id)aValue
      fromRemoteKeyPath:(NSString *)aRemoteKeyPath
         toLocalKeyPath:(NSString *)aLocalKeyPath {

  if ( [aRemoteKeyPath isEqualToString:@"tagged_uids"])
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:(NSArray*)aValue options:0 error:nil] encoding:NSUTF8StringEncoding];

  
  return [super transformedValue:aValue
               fromRemoteKeyPath:aRemoteKeyPath
                  toLocalKeyPath:aLocalKeyPath];
  
}


@end
