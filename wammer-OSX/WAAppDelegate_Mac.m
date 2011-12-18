//
//  WAAppDelegate_Mac.m
//  wammer
//
//  Created by Evadne Wu on 12/17/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAAppDelegate_Mac.h"

#import "WADefines.h"
#import "WAAppDelegate.h"
#import "WARemoteInterface.h"

#import "WATimelineWindowController.h"
#import "WAAuthRequestWindowController.h"

#import "IRKeychainManager.h"


@interface WAAppDelegate_Mac () <WAAuthRequestWindowControllerDelegate>

- (void) presentTimeline;

@end


@implementation WAAppDelegate_Mac

- (void) beginNetworkActivity {

	//	No op

}

- (void) endNetworkActivity {

	//	No op

}

- (void) bootstrap {

	[super bootstrap];
	
	[NSApp setNextResponder:self];

	[IRKeychainManager sharedManager].defaultAccessGroupName = @"waveface";

}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {

	[self bootstrap];
	
	BOOL authenticated = NO;
	
	if ([self hasAuthenticationData]) {
	
		[self presentTimeline];
	
	} else {
	
		if (![NSApp isActive])
			[NSApp requestUserAttention:NSCriticalRequest];
			
		[[WAAuthRequestWindowController sharedController] setDelegate:self];
		[[[WAAuthRequestWindowController sharedController] window] makeKeyAndOrderFront:self];
		
	}
	
}

- (void) authRequestController:(WAAuthRequestWindowController *)controller didRequestAuthenticationForUserName:(NSString *)proposedUsername password:(NSString *)proposedPassword withCallback:(void (^)(BOOL))aCallback {

	NSParameterAssert(proposedUsername);
	NSParameterAssert(proposedPassword);
	
	NSParameterAssert([WARemoteInterface sharedInterface]);

	WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	
	[ri retrieveTokenForUser:proposedUsername password:proposedPassword onSuccess:^(NSDictionary *userRep, NSString *token) {
		
		dispatch_async(dispatch_get_main_queue(), ^ {

			[self updateCurrentCredentialsWithUserIdentifier:[userRep objectForKey:@"user_id"] token:token primaryGroup:[[[userRep objectForKey:@"groups"] lastObject] valueForKeyPath:@"group_id"]];

			if (aCallback)
				aCallback(YES);
			
			[self presentTimeline];
			
		});

	} onFailure:^(NSError *error) {
	
		dispatch_async(dispatch_get_main_queue(), ^ {
		
			aCallback(NO);

		});
		
	}];

}

- (void) presentTimeline {

	NSParameterAssert([self hasAuthenticationData]);

	WATimelineWindowController *timelineWC = [WATimelineWindowController sharedController];
	
	timelineWC.nextResponder = self;

	[[timelineWC window] makeKeyAndOrderFront:self];

}

- (BOOL) applicationOpenUntitledFile:(NSApplication *)sender {

	return NO;

}

@end
