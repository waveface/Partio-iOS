//
//  WARemoteInterface+Users.h
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"

@interface WARemoteInterface (Users)

//	Massage
+ (NSDictionary *) userEntityFromRepresentation:(NSDictionary *)remoteResponse;

//	POST auth/signup
- (void) registerUser:(NSString *)anIdentifier password:(NSString *)aPassword nickname:(NSString *)aNickname onSuccess:(void(^)(NSDictionary *userRep))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	GET users/get
- (void) retrieveUser:(NSString *)anIdentifier onSuccess:(void(^)(NSDictionary *userRep))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	POST users/update
- (void) updateUser:(NSString *)anIdentifier withNickname:(NSString *)aNewNickname onSuccess:(void(^)(NSDictionary *userRep))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	POST users/passwd
- (void) resetPasswordOfCurrentUserFrom:(NSString *)anOldPassword To:(NSString *)aNewPassword onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock;

@end
