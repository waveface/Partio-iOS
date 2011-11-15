//
//  WARemoteInterface+Groups.h
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"

@interface WARemoteInterface (Groups)

//	POST groups/create
- (void) createGroupNamed:(NSString *)aName withDescription:(NSString *)aDescription onSuccess:(void(^)(NSDictionary *groupRep))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	GET groups/get
- (void) retrieveGroup:(NSString *)anIdentifier onSuccess:(void(^)(NSDictionary *groupRep, NSArray *activeMemberReps /* as user reps */))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	POST groups/update
- (void) updateGroup:(NSString *)anIdentifier withName:(NSString *)aNewNameOrNil description:(NSString *)aNewDescriptionOrNil onSuccess:(void(^)(NSDictionary *groupRep))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	POST groups/delete
- (void) deleteGroup:(NSString *)anIdentifier onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	POST groups/inviteUser
- (void) addUser:(NSString *)anUserIdentifier toGroup:(NSString *)aGroupIdentifier onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock;

//	POST groups/kickUser
- (void) removeUser:(NSString *)anUserIdentifier fromGroup:(NSString *)aGroupIdentifier onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock;

@end
