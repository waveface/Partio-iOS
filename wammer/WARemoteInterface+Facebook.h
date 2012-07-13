//
//  WARemoteInterface+Facebook.h
//  IRObjectQueue
//
//  Created by jamie on 7/5/12.
//  Copyright (c) 2012 Iridia Productions. All rights reserved.
//

#import "WARemoteInterface.h"

@interface WARemoteInterface (Facebook)

- (void) signupUserWithFacebookToken:(NSString *) accessToken withOptions: (NSDictionary *)options onSuccess:(void(^)(NSString *token, NSDictionary *userRep, NSArray *groupReps)) successBlock onFailure: (void(^)(NSError *error)) failureBlock;

@end
