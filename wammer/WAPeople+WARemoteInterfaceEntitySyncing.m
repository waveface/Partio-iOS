//
//  WAPeople+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Shen Steven on 11/8/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAPeople+WARemoteInterfaceEntitySyncing.h"
#import <MagicalRecord/MagicalRecord.h>
#import <NSManagedObject+MagicalRecord.h>
#import <NSManagedObject+MagicalFinders.h>

@implementation WAPeople (WARemoteInterfaceEntitySyncing)

+ (NSString *) keyPathHoldingUniqueValue {
	
  return @"email";
	
}

+ (BOOL) skipsNonexistantRemoteKey {
	
  return YES;
	
}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {
  NSMutableDictionary *returnedDictionary = [incomingRepresentation mutableCopy];

  NSString *email = returnedDictionary[@"email"];
  NSString *fbid = returnedDictionary[@"fbid"];
  if (!email && fbid) {
    WAPeople *personRecord = [WAPeople MR_findFirstByAttribute:@"fbid" withValue:fbid];
    if (personRecord && personRecord.email) {
      returnedDictionary[@"email"] = personRecord.email;
    }
  }
  
  return returnedDictionary;
	
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {
	
	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
                   @"name", @"nickname",
                   @"email", @"email",
                   @"avatarURL", @"avatar_url",
                   @"avatarURL", @"avatar",
                   @"identifier", @"user_id",
                   @"fbID", @"fbid",
                   nil];
		
	});
	
	return mapping;
	
}

@end
