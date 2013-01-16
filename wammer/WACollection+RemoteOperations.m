//
//  WACollection+RemoteOperations.m
//  wammer
//
//  Created by jamie on 1/4/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WACollection+RemoteOperations.h"
#import "WARemoteInterface+Authentication.h"
#import "WARemoteInterface+Reachability.h"

#import <MKNetworkKit/MKNetworkKit.h>
#import <MagicalRecord/NSManagedObjectContext+MagicalRecord.h>

@implementation WACollection (RemoteOperations)

+ (void)refreshCollectionsWithCompletion:(void (^)(void))completionBlock
{
  WARemoteInterface *interface = [WARemoteInterface sharedInterface];
  NSURL *bestURL = [interface bestHostForRequestNamed:@"collections/getAll"];
  MKNetworkEngine *engine = [[MKNetworkEngine alloc] initWithHostName:[bestURL host] apiPath:@"v3" customHeaderFields:nil];
  
  NSDictionary *payload = @{
  @"session_token":interface.userToken,
  @"api_key":interface.apiKey,
  @"no_hidden":@YES,
  };
  
  MKNetworkOperation *op = [engine operationWithPath:@"collections/getAll"
                                              params:payload
                                          httpMethod:@"GET"
                                                 ssl:[[bestURL scheme] isEqualToString:@"https"]];
  
  op.freezable = YES;
  [op
   addCompletionHandler:^(MKNetworkOperation *completedOperation) {
     NSError *error;
     NSDictionary *response = [NSJSONSerialization JSONObjectWithData:[completedOperation responseData]
                                                              options:NSJSONReadingAllowFragments
                                                                error:&error];
	 NSManagedObjectContext *moc = [NSManagedObjectContext MR_context];
     moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
     
     [WACollection
      insertOrUpdateObjectsUsingContext:moc
      withRemoteResponse:[response objectForKey:@"collections"]
      usingMapping:nil
      options:IRManagedObjectOptionIndividualOperations
      ];
	 NSError *saveError;
     if( [moc save:&saveError] ) {
	   completionBlock();
	   [[NSNotificationCenter defaultCenter] postNotificationName:kWACollectionUpdated object:completedOperation];
	 }else {
	   CLSNSLog(@"Upsert Collection error: %@", saveError);
	 }
   }
   errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
     completionBlock();
     [[NSNotificationCenter defaultCenter] postNotificationName:kWACollectionUpdated object:completedOperation];
     CLSNSLog(@"GET collection/get failed");
   }];
  
  //  MKNetworkOperation *op = [engine operationWithPath:@"https://develop.waveface.com/v2/attachments/multiple_get?session_token=b31tbLA0SYCwHXDZR9qf7A2n.fIn9nQMUri8c5J%2Fgi3stz0w5CgE7i5E6PNGSDz9QLM8&apikey=ca5c3c5c-287d-5805-93c1-a6c2cbf9977c"];
  [engine enqueueOperation:op];
}

+ (WACollection *)create {
  WARemoteInterface *interface = [WARemoteInterface sharedInterface];
  NSURL *bestURL = [interface bestHostForRequestNamed:@"collections/create"];
  MKNetworkEngine *engine = [[MKNetworkEngine alloc] initWithHostName:[bestURL host]
                                                              apiPath:@"v3"
                                                   customHeaderFields:nil];
  NSDictionary *payload = @{
  @"session_token":interface.userToken,
  @"api_key":interface.apiKey,
  @"manual":@"true",
  @"name":@"Created by shake.",
  @"object_id_list": [@[@"88704d05-88e7-4464-ac0a-e47081fb3185"] JSONString],
  };
  
  MKNetworkOperation *op = [engine operationWithPath:@"collections/create"
                                              params:payload
                                          httpMethod:@"POST"
                                                 ssl:[[bestURL scheme] isEqualToString:@"https"]];
  [engine enqueueOperation:op];
  
  return nil;
}

- (void)addObjects:(NSArray *)objects {
  NSMutableOrderedSet *items = [self.files mutableCopy];
  [items addObjectsFromArray:objects];
  self.files = items;
  NSError *error;
  [[self managedObjectContext] save:&error];
  if (error) {
	CLSNSLog(@"Add object to Collect error: %@", error);
  }
  
  WARemoteInterface *interface = [WARemoteInterface sharedInterface];
  NSURL *bestURL = [interface bestHostForRequestNamed:@"collections/update"];
  MKNetworkEngine *engine = [[MKNetworkEngine alloc] initWithHostName:[bestURL host]
                                                              apiPath:@"v3"
                                                   customHeaderFields:nil];
  NSDictionary *payload = @{
  @"session_token":interface.userToken,
  @"api_key":interface.apiKey,
  @"object_id_list":[self.files valueForKeyPath:@"identifier"],
  };
  MKNetworkOperation *op = [engine operationWithPath:@"collections/update"
                                              params:payload
                                          httpMethod:@"POST"
                                                 ssl:[[bestURL scheme] isEqualToString:@"https"]];
  [engine enqueueOperation:op];
}

@end

NSString *const kWACollectionUpdated = @"WACollectionUpdated";
