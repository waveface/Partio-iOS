//
//  WAStation+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by kchiu on 13/1/8.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAStation+WARemoteInterfaceEntitySyncing.h"

@implementation WAStation (WARemoteInterfaceEntitySyncing)

+ (NSString *) keyPathHoldingUniqueValue {
  
  return @"identifier";
  
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {
  
  static NSDictionary *mapping = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    
    mapping = @{
    @"station_id": @"identifier",
    @"ws_location": @"wsURL",
    @"location": @"httpURL",
    @"computer_name": @"name"
    };
    
  });
  
  return mapping;
  
}

@end
