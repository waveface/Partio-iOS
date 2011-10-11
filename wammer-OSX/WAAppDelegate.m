//
//  WAAppDelegate.m
//  wammer-OSX
//
//  Created by Evadne Wu on 10/9/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "WADefines.h"
#import "WAAppDelegate.h"
#import "WARemoteInterface.h"

#import "WATimelineWindowController.h"
#import "WAAuthRequestWindowController.h"


@interface WAAppDelegate () <WAAuthRequestWindowControllerDelegate>

- (void) presentTimeline;

@end


@implementation WAAppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {

	WARegisterUserDefaults();
	
	BOOL authenticated = NO;
	
	if (authenticated) {
	
		[self presentTimeline];
	
	} else {
	
		if (![NSApp isActive])
			[NSApp requestUserAttention:NSCriticalRequest];
			
		[[WAAuthRequestWindowController sharedController] setDelegate:self];
		[[[WAAuthRequestWindowController sharedController] window] makeKeyAndOrderFront:self];
		
	}
	
//	[[[WATimelineWindowController sharedController] window] makeKeyAndOrderFront:self];
	
//	[[WARemoteInterface sharedInterface] retrieveTokenForUserWithIdentifier:@"evadne.wu@waveface.com" password:@"evadne" onSuccess:^(NSDictionary *userRep, NSString *token) {
//		
//		[[WARemoteInterface sharedInterface] setUserIdentifier:[userRep objectForKey:@"creator_id"]];
//		[[WARemoteInterface sharedInterface] setUserToken:token];
//		
//		[[WADataStore defaultStore] updateUsersOnSuccess:^{
//			NSLog(@"users refreshed");
//			[[WADataStore defaultStore] updateArticlesOnSuccess:^{
//				NSLog(@"articles refreshed");
//			} onFailure:^{
//				NSLog(@"articles load failed");
//			}];
//		} onFailure:^{
//			NSLog(@"user load failed");
//		}];
//			
//	} onFailure: ^ (NSError *error) {
//	
//		NSLog(@"%@", error);
//		
//	}];
	
}

- (void) authRequestController:(WAAuthRequestWindowController *)controller didRequestAuthenticationForUserName:(NSString *)proposedUsername password:(NSString *)proposedPassword withCallback:(void (^)(BOOL))aCallback {

	NSParameterAssert(proposedUsername);
	NSParameterAssert(proposedPassword);
	
	NSParameterAssert([WARemoteInterface sharedInterface]);

	[[WARemoteInterface sharedInterface] retrieveTokenForUserWithIdentifier:proposedUsername password:proposedPassword onSuccess:^(NSDictionary *userRep, NSString *token) {
		
		dispatch_async(dispatch_get_main_queue(), ^ {
		
			if (aCallback)
				aCallback(YES);
				
			[[WARemoteInterface sharedInterface] setUserIdentifier:[userRep objectForKey:@"creator_id"]];
			[[WARemoteInterface sharedInterface] setUserToken:token];
			
			[self presentTimeline];

			[[WADataStore defaultStore] updateUsersOnSuccess: ^ {
				
				[[WADataStore defaultStore] updateArticlesOnSuccess: ^ {
				
					NSLog(@"everything here");
				
				} onFailure: ^ {
					
					NSLog(@"articles load failed");
					
				}];
				
			} onFailure: ^ {
				
				NSLog(@"user load failed");
				
			}];
			
		});
		
	} onFailure: ^ (NSError *error) {
	
		dispatch_async(dispatch_get_main_queue(), ^ {
		
			if (aCallback)
				aCallback(NO);
			
		});
		
	}];

}

- (void) presentTimeline {

	[[[WATimelineWindowController sharedController] window] makeKeyAndOrderFront:self];

}

@end
