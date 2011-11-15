//
//  WARemoteInterface+Groups.m
//  ;
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface+Groups.h"

@implementation WARemoteInterface (Groups)

- (void) createGroupNamed:(NSString *)aName withDescription:(NSString *)aDescription onSuccess:(void(^)(NSDictionary *groupRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSParameterAssert(aName);
	
	[self.engine fireAPIRequestNamed:@"groups/create" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
	
		aName, @"name",
		aDescription, @"description",
	
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (!successBlock)
			return;
		
		successBlock([inResponseOrNil valueForKey:@"group"]);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveGroup:(NSString *)anIdentifier onSuccess:(void(^)(NSDictionary *groupRep, NSArray *activeMemberReps /* as user reps */))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSParameterAssert(anIdentifier);
	
	[self.engine fireAPIRequestNamed:@"groups/get" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		anIdentifier, @"group_id",
	
	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (!successBlock)
			return;
		
		successBlock(
			[inResponseOrNil valueForKey:@"group"],
			[inResponseOrNil valueForKey:@"active_members"]
		);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) updateGroup:(NSString *)anIdentifier withName:(NSString *)aNewNameOrNil description:(NSString *)aNewDescriptionOrNil onSuccess:(void(^)(NSDictionary *groupRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSParameterAssert(anIdentifier);
	
	NSMutableDictionary *sentData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		anIdentifier, @"group_id", 
	nil];
	
	if (aNewNameOrNil)
		[sentData setObject:aNewNameOrNil forKey:@"name"];
		
	if (aNewDescriptionOrNil)
		[sentData setObject:aNewDescriptionOrNil forKey:@"description"];		

	[self.engine fireAPIRequestNamed:@"groups/update" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary(sentData, nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock([inResponseOrNil valueForKey:@"group"]);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) deleteGroup:(NSString *)anIdentifier onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock {
	
	NSParameterAssert(anIdentifier);
	
	[self.engine fireAPIRequestNamed:@"groups/delete" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
	
		anIdentifier, @"group_id",
	
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock();
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) addUser:(NSString *)anUserIdentifier toGroup:(NSString *)aGroupIdentifier onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSParameterAssert(anUserIdentifier);
	NSParameterAssert(aGroupIdentifier);
	
	[self.engine fireAPIRequestNamed:@"groups/inviteUser" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
	
		aGroupIdentifier, @"group_id",
		anUserIdentifier, @"user_id",
	
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock();
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) removeUser:(NSString *)anUserIdentifier fromGroup:(NSString *)aGroupIdentifier onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSParameterAssert(anUserIdentifier);
	NSParameterAssert(aGroupIdentifier);

	[self.engine fireAPIRequestNamed:@"groups/kickUser" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
	
		aGroupIdentifier, @"group_id",
		anUserIdentifier, @"user_id",
	
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock();
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

@end
