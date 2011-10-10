//
//  WAAppDelegate.m
//  wammer-OSX
//
//  Created by Evadne Wu on 10/9/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "WADefines.h"
#import "WAAppDelegate.h"
#import "WATimelineWindowController.h"
#import "WARemoteInterface.h"

@implementation WAAppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {

	WARegisterUserDefaults();

	[[[WATimelineWindowController sharedController] window] makeKeyAndOrderFront:self];
	
	[[WARemoteInterface sharedInterface] retrieveTokenForUserWithIdentifier:@"evadne.wu@waveface.com" password:@"evadne" onSuccess:^(NSDictionary *userRep, NSString *token) {
	
		NSLog(@"%@ %@", userRep, token);
		
		[[WARemoteInterface sharedInterface] setUserIdentifier:[userRep objectForKey:@"creator_id"]];
		[[WARemoteInterface sharedInterface] setUserToken:token];
		
		[[WADataStore defaultStore] updateUsersOnSuccess:^{
			NSLog(@"users refreshed");
			[[WADataStore defaultStore] updateArticlesOnSuccess:^{
				NSLog(@"articles refreshed");
			} onFailure:^{
				NSLog(@"articles load failed");
			}];
		} onFailure:^{
			NSLog(@"user load failed");
		}];
			
	} onFailure: ^ (NSError *error) {
	
		NSLog(@"%@", error);
		
	}];
	
}

@end
