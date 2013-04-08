//
//  FBRequestConnection+WAAdditions.h
//  wammer
//
//  Created by Shen Steven on 4/6/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>

@interface FBRequestConnection (WAAdditions)

+ (FBRequestConnection*)startForUserCheckinsAfterId:(NSNumber*)latestCheckinID completeHandler:(FBRequestHandler)completionBlock;

@end
