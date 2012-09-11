//
//  WAFacebookInterface.m
//  wammer
//
//  Created by Evadne Wu on 7/11/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFacebookInterface.h"
#import "Facebook.h"
#import "WAFacebook.h"
#import "WADefines.h"
#import "WAFacebookInterfaceSubclass.h"


static NSString * const WAFacebookPermissionEmail = @"email";
static NSString * const WAFacebookPermissionUserPhotos = @"user_photos";
static NSString * const WAFacebookPermissionUserVideos = @"user_videos";
static NSString * const WAFacebookPermissionUserNotes = @"user_notes";
static NSString * const WAFacebookPermissionUserStatus = @"user_status";
static NSString * const WAFacebookPermissionReadStream = @"read_stream";

static NSString * const WAFacebookCallbackTrampolineNotification = @"WAFacebookCallbackTrampolineNotification";
static NSString * const WAFacebookCallbackTrampolineMethodNameKey = @"WAFacebookCallbackTrampolineMethodNameKey";

static NSString * const WAFacebookCallbackDidLoginMethodName = @"WAFacebookCallbackDidLoginMethodName";
static NSString * const WAFacebookCallbackDidNotLoginMethodName = @"WAFacebookCallbackDidNotLoginMethodName";


@implementation WAFacebookInterface
@synthesize facebook = _facebook;

+ (WAFacebookInterface *) sharedInterface {

	static dispatch_once_t onceToken;
	static WAFacebookInterface *interface;
	
	dispatch_once(&onceToken, ^{
	
		interface = [self new];
		
		interface.userDataImporting = NO;
	
	});
	
	return interface;

}

- (Facebook *) facebook {

	if (!_facebook) {
	
		_facebook = [[WAFacebook alloc] initWithAppId:[[NSUserDefaults standardUserDefaults] objectForKey:kWAFacebookAppID] andDelegate:self];
	
	}
	
	return _facebook;

}

- (void) authenticateWithCompletion:(void(^)(BOOL didFinish, NSError *error))block {

	Facebook * const fbInstance = self.facebook;
	NSArray * const fbPermissions = [self copyRequestedPermissions];
	__weak NSNotificationCenter * const center = [NSNotificationCenter defaultCenter];
	
	__block id listener = [center addObserverForName:WAFacebookCallbackTrampolineNotification object:self queue:nil usingBlock:^(NSNotification *note) {

		NSDictionary *userInfo = [note userInfo];
		NSString *methodName = [userInfo objectForKey:WAFacebookCallbackTrampolineMethodNameKey];
		
		if ([methodName isEqualToString:WAFacebookCallbackDidLoginMethodName]) {
		
			if (block)
				block(YES, nil);
		
			[center removeObserver:listener];
			listener = nil;
			
			return;
		
		} else if ([methodName isEqualToString:WAFacebookCallbackDidNotLoginMethodName]) {
		
			if (block)
				block(NO, nil);
			
			[center removeObserver:listener];
			listener = nil;
			
			return;
		
		}
		
	}];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	fbInstance.accessToken = [defaults objectForKey:kFBAccessToken];
	fbInstance.expirationDate = (NSDate *)[defaults objectForKey:kFBExpirationDate];
	
	if (fbInstance.isSessionValid){
		[self fbDidLogin];
	} else {
		[fbInstance authorize:fbPermissions];
	}

}

- (NSArray *) copyRequestedPermissions {

	return [NSArray arrayWithObjects:
		WAFacebookPermissionEmail,
		WAFacebookPermissionUserPhotos,
		WAFacebookPermissionUserVideos,
		WAFacebookPermissionUserNotes,
		WAFacebookPermissionUserStatus,
		WAFacebookPermissionReadStream,
	nil];
	
}

- (void) fbDidLogin {

	[self bounceCallbackWithMethod:WAFacebookCallbackDidLoginMethodName userInfo:nil];

}

- (void) fbDidNotLogin:(BOOL)cancelled {

	[self bounceCallbackWithMethod:WAFacebookCallbackDidNotLoginMethodName userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
	
		(id)(cancelled ? kCFBooleanTrue : kCFBooleanFalse), @"cancelled",
	
	nil]];

}

- (void) fbDidExtendToken:(NSString*)accessToken expiresAt:(NSDate*)expiresAt {

	[self assertNotReached];

}

- (void) fbDidLogout {

	[self assertNotReached];

}

- (void) fbSessionInvalidated {

	[self assertNotReached];
	
}

- (void) bounceCallbackWithMethod:(NSString *)methodName userInfo:(NSDictionary *)userInfo {

	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	NSMutableDictionary *sentUserInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		methodName, WAFacebookCallbackTrampolineMethodNameKey,
	nil];
	
	[sentUserInfo addEntriesFromDictionary:userInfo];
	
	[center postNotificationName:WAFacebookCallbackTrampolineNotification object:self userInfo:sentUserInfo];

}

- (void) assertNotReached {

	[NSException raise:NSInternalInconsistencyException format:@"Method should not be reached."];

}

@end
