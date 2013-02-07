//
//  WARemoteInterface+Usertracks.m
//  wammer
//
//  Created by Evadne Wu on 3/26/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARemoteInterface+Usertracks.h"
#import "WADataStore.h"
#import <SSToolkit/NSDate+SSToolkitAdditions.h>

@implementation WARemoteInterface (Usertracks)

- (void)retrieveChangesSince:(NSNumber *)aSeq inGroup:(NSString *)aGroupIdentifier onSuccess:(void (^)(NSArray *, NSArray *, NSArray *, NSNumber *))successBlock onFailure:(void (^)(NSError *))failureBlock {

  NSParameterAssert(aGroupIdentifier);

  NSDictionary *arguments = nil;
  if (aSeq) {
    arguments = @{@"group_id":aGroupIdentifier, @"since_seq_num":aSeq};
  } else {
    arguments = @{@"group_id":aGroupIdentifier};
  }

  [self.engine fireAPIRequestNamed:@"changelogs/get"
					 withArguments:nil
						   options:@{kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey:arguments ,kIRWebAPIEngineRequestHTTPMethod: @"POST"}
						 validator:WARemoteInterfaceGenericNoErrorValidator()
					successHandler:^(NSDictionary *response, IRWebAPIRequestContext *context) {

    NSArray *changedArticles = response[@"post_list"];
    NSArray *changedFiles = response[@"attachment_list"];
    NSNumber *nextSeq = response[@"next_seq_num"];
    
    if (successBlock) {
      successBlock(changedArticles, changedFiles, response[@"collection_list"], nextSeq);
    }

  } failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveChangesSince:(NSDate *)date inGroup:(NSString *)groupID withEntities:(BOOL)includesEntities onSuccess:(void(^)(NSArray *changedArticleIDs, NSArray *changedFileIDs, NSArray* changes, NSDate *continuation))successBlock onFailure:(void(^)(NSError *error))failureBlock {
  
  NSDate *usedSinceDate = date ? date : [NSDate dateWithTimeIntervalSince1970:0];
  NSString *dateString = [usedSinceDate ISO8601String];
  
  [self.engine fireAPIRequestNamed:@"usertracks/get" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
						        
						        groupID, @"group_id",
						        (includesEntities ? @"true" : @"false"), @"include_entities",
						        dateString, @"since",
						        
						        nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
    
    NSArray *changedArticleIDs = [inResponseOrNil valueForKeyPath:@"post_id_list"];
    NSArray *changedFileIDs = [inResponseOrNil valueForKeyPath:@"attachment_id_list"];
    NSArray *changeOperations = [inResponseOrNil valueForKeyPath:@"usertrack_list"];
    NSString *continuationString = [inResponseOrNil valueForKeyPath:@"latest_timestamp"];
    
    if (![continuationString length])
      continuationString = nil;
    
    NSDate *continuation = [NSDate dateFromISO8601String:continuationString];
    
    if (successBlock)
      successBlock(changedArticleIDs, changedFileIDs, changeOperations, continuation);
    
  } failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];
  
}

@end
