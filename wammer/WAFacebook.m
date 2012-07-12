//
//  WAFacebook.m
//  wammer
//
//  Created by Evadne Wu on 7/12/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFacebook.h"


@interface Facebook (KnownPrivate)

- (void) authorizeWithFBAppAuth:(BOOL)tryFBAppAuth safariAuth:(BOOL)trySafariAuth;

@end


@implementation WAFacebook

- (void) authorizeWithFBAppAuth:(BOOL)tryFBAppAuth safariAuth:(BOOL)trySafariAuth {

	[super authorizeWithFBAppAuth:tryFBAppAuth safariAuth:trySafariAuth];
	//	[super authorizeWithFBAppAuth:NO safariAuth:NO];

}

@end
