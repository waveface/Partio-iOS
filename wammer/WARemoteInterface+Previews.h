//
//  WARemoteInterface+Previews.h
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"

@interface WARemoteInterface (Previews)

//	GET previews/get
- (void) retrievePreviewForURL:(NSURL *)aRemoteURL onSuccess:(void(^)(NSDictionary *aPreviewRep))successBlock onFailure:(void(^)(NSError *error))failureBlock;

@end
