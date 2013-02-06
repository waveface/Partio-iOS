//
//  WARemoteInterface+Users.m
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WADefines.h"
#import "WARemoteInterface+Users.h"
#import "IRWebAPIEngine+FormURLEncoding.h"

@implementation WARemoteInterface (Users)

+ (NSDictionary *) userEntityFromRepresentation:(NSDictionary *)remoteResponse {
  
  NSMutableDictionary *userEntity = [[remoteResponse valueForKeyPath:@"user"] mutableCopy];
  
  if (![userEntity isKindOfClass:[NSDictionary class]])
    userEntity = [NSMutableDictionary dictionary];
  
  NSArray *groupReps = [remoteResponse valueForKeyPath:@"groups"];
  if (groupReps)
    userEntity[@"groups"] = groupReps;
  
  NSArray *stationReps = [remoteResponse valueForKeyPath:@"stations"];
  if (stationReps)
    userEntity[@"stations"] = stationReps;
  
  NSDictionary *quotaRep = [remoteResponse valueForKeyPath:@"quota"];
  if (quotaRep)
    userEntity[@"quota"] = quotaRep;
  
  NSDictionary *usageRep = [remoteResponse valueForKeyPath:@"usage"];
  if (usageRep)
    userEntity[@"usage"] = usageRep;
  
  NSDictionary *billingRep = [remoteResponse valueForKeyPath:@"billing"];
  if (billingRep) {
    userEntity[@"billing"] = billingRep;
  }
  
  return userEntity;
  
}

- (void) registerUser:(NSString *)anIdentifier password:(NSString *)aPassword nickname:(NSString *)aNickname onSuccess:(void (^)(NSString *, NSDictionary *, NSArray *))successBlock onFailure:(void (^)(NSError *))failureBlock {
  
  NSParameterAssert(anIdentifier);
  NSParameterAssert(aNickname);
  
  [self.engine fireAPIRequestNamed:@"auth/signup" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
													   
													   anIdentifier, @"email",
													   aPassword, @"password",
													   aNickname, @"nickname",
													   WADeviceName(), @"device_name",
													   WADeviceIdentifier(), @"device_id",
													   
													   nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
    
    if (successBlock) {
      successBlock(
	         [inResponseOrNil valueForKeyPath:@"session_token"],
	         [inResponseOrNil valueForKeyPath:@"user"],
	         [inResponseOrNil valueForKeyPath:@"groups"]
	         );
    }
    
  } failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];
  
}

- (void) retrieveUserWithoutFurtherParsing:(NSString *)anIdentifier onSuccess:(void (^)(NSDictionary *))successBlock onFailure:(void (^)(NSError *))failureBlock {
  
  NSParameterAssert(anIdentifier);
  NSDictionary *arguments = @{@"user_id": anIdentifier};
  [self.engine fireAPIRequestNamed:@"users/get"
					 withArguments:nil
						   options:@{kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey:arguments ,kIRWebAPIEngineRequestHTTPMethod: @"POST"}
						 validator:WARemoteInterfaceGenericNoErrorValidator()
					successHandler: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
    
    if (successBlock)
      successBlock(inResponseOrNil);
    
  } failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];
  
}


- (void) retrieveUser:(NSString *)anIdentifier onSuccess:(void (^)(NSDictionary *))successBlock onFailure:(void (^)(NSError *))failureBlock {
  
  [self retrieveUserWithoutFurtherParsing:anIdentifier onSuccess:^(NSDictionary *inResponseOrNil) {
    
    if (successBlock)
      successBlock([[self class] userEntityFromRepresentation:inResponseOrNil]);
    
  } onFailure:failureBlock];
  
  
}



- (void) retrieveUserAndSNSInfo:(NSString *) anIdentifier onSuccess:(void (^)(NSDictionary *, NSArray*))successBlock onFailure:(void (^)(NSError *))failureBlock {
  
  [self retrieveUserWithoutFurtherParsing:anIdentifier onSuccess:^(NSDictionary *inResponseOrNil) {
    
    NSArray *snsEntitiesOrNil = nil;
    if (inResponseOrNil)
      snsEntitiesOrNil = [inResponseOrNil valueForKeyPath:@"sns"];
    
    if (successBlock)
      successBlock([[self class] userEntityFromRepresentation:inResponseOrNil], snsEntitiesOrNil);
    
  } onFailure:failureBlock];
  
  
}


- (void) updateUser:(NSString *)anIdentifier withNickname:(NSString *)aNewNickname onSuccess:(void (^)(NSDictionary *))successBlock onFailure:(void (^)(NSError *))failureBlock {
  
  [self.engine fireAPIRequestNamed:@"users/update" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
													    
													    anIdentifier, @"user_id",
													    aNewNickname, @"nickname",
													    
													    nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
    
    if (successBlock)
      successBlock([[self class] userEntityFromRepresentation:inResponseOrNil]);
    
  } failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];
  
}

- (void) updateUser:(NSString *)anIdentifier withEmail:(NSString *)aNewEmail onSuccess:(void (^)(NSDictionary *))successBlock onFailure:(void (^)(NSError *))failureBlock {

  [self.engine fireAPIRequestNamed:@"users/update"
					 withArguments:nil
						   options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary(@{@"user_id": anIdentifier, @"email": aNewEmail}, nil)
						 validator:WARemoteInterfaceGenericNoErrorValidator()
					successHandler:^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *context) {
					  
					  if (successBlock)
						successBlock([[self class] userEntityFromRepresentation:inResponseOrNil]);
					  
					}
					failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];
  
}

- (void) resetPasswordOfCurrentUserFrom:(NSString *)anOldPassword To:(NSString *)aNewPassword onSuccess:(void (^)(void))successBlock onFailure:(void (^)(NSError *))failureBlock {
  
  [self.engine fireAPIRequestNamed:@"users/passwd" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
													    
													    anOldPassword, @"old_passwd",
													    aNewPassword, @"new_passwd",
													    
													    nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
    
    if (successBlock)
      successBlock();
    
  } failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];
  
}

- (void) deleteUserWithEmailSentOnSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock {
  
  [self.engine fireAPIRequestNamed:@"users/deleteWithEmail" withArguments:nil options:nil validator:WARemoteInterfaceGenericNoErrorValidator()
					successHandler:^(NSDictionary *response, IRWebAPIRequestContext *context) {
					  successBlock();
					} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];
  
}

@end
