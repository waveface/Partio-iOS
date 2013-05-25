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
                @"checkin_id": @"identifier",
                @"timestamp": @"createDate",
                @"tagged_uids": @"taggedUsers",
                @"latitude": @"latitude",
                @"longitude": @"longitude"
                };
    
  });
  
  return mapping;
  
}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {
  
  NSMutableDictionary *transformedRepresentation = [NSMutableDictionary dictionaryWithDictionary:incomingRepresentation];

  id checkinIdRep = incomingRepresentation[@"checkin_id"];
  if (checkinIdRep) {
    if ([checkinIdRep isKindOfClass:[NSNumber class]]) {
      transformedRepresentation[@"checkin_id"] = [NSString stringWithFormat:@"%@", checkinIdRep];
    }
  }
  
  return transformedRepresentation;
}

+ (id) transformedValue:(id)aValue
      fromRemoteKeyPath:(NSString *)aRemoteKeyPath
         toLocalKeyPath:(NSString *)aLocalKeyPath {

  if ([aRemoteKeyPath isEqualToString:@"timestamp"])
    return [NSDate dateWithTimeIntervalSince1970:[aValue intValue]];
  
  if ([aRemoteKeyPath isEqualToString:@"checkin_id"])
    return [NSString stringWithFormat:@"%@", aValue];

  if ( [aRemoteKeyPath isEqualToString:@"tagged_uids"])
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:(NSArray*)aValue options:0 error:nil] encoding:NSUTF8StringEncoding];

  
  return [super transformedValue:aValue
               fromRemoteKeyPath:aRemoteKeyPath
                  toLocalKeyPath:aLocalKeyPath];
  
}


@end
