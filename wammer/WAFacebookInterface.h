//
//  WAFacebookInterface.h
//  wammer
//
//  Created by Evadne Wu on 7/11/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WAFacebookInterface : NSObject

+ (WAFacebookInterface *) sharedInterface;

- (void) authenticateWithCompletion:(void(^)(BOOL didFinish, NSError *error))block;

@end
