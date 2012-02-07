//
//  WARemoteInterface+Previews.m
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface+Previews.h"

@implementation WARemoteInterface (Previews)

- (void) retrievePreviewForURL:(NSURL *)aRemoteURL onSuccess:(void(^)(NSDictionary *aPreviewRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"previews/get" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:

		[aRemoteURL absoluteString], @"url",
		
		//	Advanced flag is deprecated
		//	kCFBooleanTrue, @"adv",

	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (!successBlock)
			return;
		
		successBlock([inResponseOrNil valueForKey:@"preview"]);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

@end
