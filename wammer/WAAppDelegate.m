//
//  WAAppDelegate.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAAppDelegate.h"
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import "WAAppDelegate_iOS.h"
#else
#import "WAAppDelegate_Mac.h"
#endif


#import "WAAppDelegate.h"
#import "WADefines.h"
#import "WARemoteInterface.h"
#import "WADataStore.h"

#import "IRRelativeDateFormatter+WAAdditions.h"

#import "IRRemoteResourcesManager.h"
#import "IRRemoteResourceDownloadOperation.h"
#import "IRWebAPIEngine+ExternalTransforms.h"
#import "SSKeychain.h"

#define MR_SHORTHAND
#import "CoreData+MagicalRecord.h"

@interface WAAppDelegate () <IRRemoteResourcesManagerDelegate>

+ (Class) preferredClusterClass;

@end


@implementation WAAppDelegate

+ (id) alloc {

  if ([self isEqual:[WAAppDelegate class]])
    return [[self preferredClusterClass] alloc];
  
  return [super alloc];
  
}

+ (id) allocWithZone:(NSZone *)zone {
  
  if ([self isEqual:[WAAppDelegate class]])
    return [[self preferredClusterClass] allocWithZone:zone];

  return [super allocWithZone:zone];
  
}

+ (Class) preferredClusterClass {

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
  return [WAAppDelegate_iOS class];
#else
	return [WAAppDelegate_Mac class];
#endif

}

- (void) bootstrap {

	WARegisterUserDefaults();
	
  [IRRelativeDateFormatter sharedFormatter].approximationMaxTokenCount = 1;
	
	[IRRemoteResourcesManager sharedManager].delegate = self;
	[IRRemoteResourcesManager sharedManager].queue.maxConcurrentOperationCount = 4;
	[IRRemoteResourcesManager sharedManager].onRemoteResourceDownloadOperationWillBegin = ^ (IRRemoteResourceDownloadOperation *anOperation) {
		
		NSMutableURLRequest *originalRequest = [anOperation underlyingRequest];
		
		NSURLRequest *transformedRequest = [[WARemoteInterface sharedInterface].engine transformedRequestWithRequest:originalRequest usingMethodName:@"loadedResource"];
		
		originalRequest.URL = transformedRequest.URL;
		originalRequest.allHTTPHeaderFields = transformedRequest.allHTTPHeaderFields;
		originalRequest.HTTPMethod = transformedRequest.HTTPMethod;
		originalRequest.HTTPBodyStream = transformedRequest.HTTPBodyStream;
		originalRequest.HTTPBody = transformedRequest.HTTPBody;
		
		
	};
	
	[IRRemoteResourcesManager sharedManager].onRemoteResourceDownloadOperationDidEnd = ^ (IRRemoteResourceDownloadOperation *anOperation) {
				dispatch_async( dispatch_get_main_queue(), ^ {
					/* Decrese networkActivityStackingCount by one, which is increased while onRemoteResourceDownloadOperationWillBegin
					 */
					[((WAAppDelegate *)[UIApplication sharedApplication].delegate) endNetworkActivity];
				});

	};
	
	[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain];
	
}

- (BOOL) hasAuthenticationData {

	NSString *lastAuthenticatedUserIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:kWALastAuthenticatedUserIdentifier];
	NSString *lastAuthenticatedUserPrimaryGroupIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:kWALastAuthenticatedUserPrimaryGroupIdentifier];

	if (!lastAuthenticatedUserIdentifier)
		return NO;
	
	NSError *error = nil;
	NSString *serviceIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	NSString *lastAuthenticatedUserSecret = [SSKeychain passwordForService:serviceIdentifier account:lastAuthenticatedUserIdentifier error:&error];
	if (error) {
		NSLog(@"Unable to fetch secret from keychain for identifier: %@", lastAuthenticatedUserIdentifier);
		return NO;
	}
	
	BOOL authenticationInformationSufficient = (lastAuthenticatedUserSecret && lastAuthenticatedUserIdentifier);
	
	if (authenticationInformationSufficient) {
	
		if (![lastAuthenticatedUserIdentifier isEqualToString:@""])
			[WARemoteInterface sharedInterface].userIdentifier = lastAuthenticatedUserIdentifier;
		
		if (lastAuthenticatedUserSecret)
			[WARemoteInterface sharedInterface].userToken = lastAuthenticatedUserSecret;
		
		if (lastAuthenticatedUserPrimaryGroupIdentifier)
			[WARemoteInterface sharedInterface].primaryGroupIdentifier = lastAuthenticatedUserPrimaryGroupIdentifier;
		
	}
  
  if ([[NSUserDefaults standardUserDefaults] boolForKey:kWAUserRequiresReauthentication])
    authenticationInformationSufficient = NO;
	
	return authenticationInformationSufficient;

}

- (BOOL) removeAuthenticationData {

	NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
	WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	
	[ri.engine.queue cancelAllOperations];

	NSHTTPCookieStorage *cs = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	for (NSHTTPCookie *cookie in [[cs cookies] copy])
		[cs deleteCookie:cookie];

	NSString *serviceIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	[SSKeychain deletePasswordForService:serviceIdentifier account:[sud stringForKey:kWALastAuthenticatedUserIdentifier]];

	[sud removeObjectForKey:kWALastAuthenticatedUserTokenKeychainItem];
	[sud removeObjectForKey:kWALastAuthenticatedUserIdentifier];
	[sud removeObjectForKey:kWALastAuthenticatedUserPrimaryGroupIdentifier];

	ri.userIdentifier = nil;
	ri.userToken = nil;
	ri.primaryGroupIdentifier = nil;

	return [sud synchronize];

}


- (void) updateCurrentCredentialsWithUserIdentifier:(NSString *)userIdentifier token:(NSString *)userToken primaryGroup:(NSString *)primaryGroupIdentifier {
	
	NSString *serviceIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	[[NSUserDefaults standardUserDefaults] setObject:userIdentifier forKey:kWALastAuthenticatedUserIdentifier];
	[[NSUserDefaults standardUserDefaults] setObject:primaryGroupIdentifier forKey:kWALastAuthenticatedUserPrimaryGroupIdentifier];
	[SSKeychain setPassword:userToken forService:serviceIdentifier account:userIdentifier];
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWAUserRequiresReauthentication];
	[[NSUserDefaults standardUserDefaults] synchronize];

}

- (void) remoteResourcesManager:(IRRemoteResourcesManager *)managed didBeginDownloadingResourceAtURL:(NSURL *)anURL {

	// FIXME: beginNetworkActivity might be called again during request transformation and causes network activity indicator always visible
	[self beginNetworkActivity];

}

- (void) remoteResourcesManager:(IRRemoteResourcesManager *)managed didFinishDownloadingResourceAtURL:(NSURL *)anURL {

	[self endNetworkActivity];

}

- (void) remoteResourcesManager:(IRRemoteResourcesManager *)managed didFailDownloadingResourceAtURL:(NSURL *)anURL {

	[self endNetworkActivity];

}

- (NSURL *) remoteResourcesManager:(IRRemoteResourcesManager *)manager invokedURLForResourceAtURL:(NSURL *)givenURL {

	if ([[givenURL host] isEqualToString:@"invalid.local"]) {
	
		NSURL *currentBaseURL = [WARemoteInterface sharedInterface].engine.context.baseURL;
    NSString *replacementScheme = [currentBaseURL scheme];
    if (!replacementScheme)
      replacementScheme = @"http";
    
		NSString *replacementHost = [currentBaseURL host];
		NSNumber *replacementPort = [currentBaseURL port];    
		
		NSString *constructedURLString = [@[[replacementScheme stringByAppendingString:@"://"],
			replacementHost,	//	[givenURL host] ? [givenURL host] : @"",
			replacementPort ? [@":" stringByAppendingString:[replacementPort stringValue]] : @"",
			[givenURL path] ? [givenURL path] : @"",
			[givenURL query] ? [@"?" stringByAppendingString:[givenURL query]] : @"",
			[givenURL fragment] ? [@"#" stringByAppendingString:[givenURL fragment]] : @""] componentsJoinedByString:@""];
		
		NSURL *constructedURL = [NSURL URLWithString:constructedURLString];
		
		return constructedURL;
		
	}
	
	return givenURL;

}

- (void) bootstrapPersistentStoreWithUserIdentifier:(NSString *)identifier {

	NSParameterAssert(identifier);
	WADataStore * const ds = [WADataStore defaultStore];
	
	ds.persistentStoreName = [identifier stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	NSManagedObjectContext *context = [ds disposableMOC];

	NSArray *existingUsers = [context executeFetchRequest:[ds newFetchRequestForUsersWithIdentifier:identifier] error:nil];
	NSUInteger numberOfExistingUsers = [existingUsers count];
	if (numberOfExistingUsers > 1) {
		
		WAUser *tentativeUser = [existingUsers lastObject];
		
		[existingUsers enumerateObjectsUsingBlock: ^ (WAUser *otherUser, NSUInteger idx, BOOL *stop) {
		
			if (otherUser == tentativeUser)
				return;
				
			[tentativeUser addArticles:otherUser.articles];
			[tentativeUser addFiles:otherUser.articles];
			[tentativeUser addGroups:otherUser.articles];
			[tentativeUser addStorages:otherUser.articles];
			
			[otherUser.managedObjectContext deleteObject:otherUser];
			
		}];
		
		[context save:nil];
		
		[ds setMainUser:tentativeUser inContext:context];
		
	}
	
	WAUser *user = [ds mainUserInContext:context];
	
	@try {
	
		[user willAccessValueForKey:nil];
	
	} @catch (NSException *e) {
	
		user = nil;
	
	}
	
	if (!user) {
		
		NSArray *foundUsers = [WAUser insertOrUpdateObjectsUsingContext:context withRemoteResponse:@[@{@"user_id": identifier}] usingMapping:nil options:0];
		
		NSCParameterAssert([foundUsers count] == 1);	
		user = [foundUsers lastObject];
		
		[context obtainPermanentIDsForObjects:@[user] error:nil];
		
		if ([context save:nil]) {
			[ds setMainUser:user inContext:context];
			[context save:nil];
		}
		
	}
	
	if (![user.identifier isEqual:identifier]) {
		user.identifier = identifier;
		[user.managedObjectContext save:nil];
	}
	
	[MagicalRecord cleanUp];
	[MagicalRecord setupCoreDataStackWithStoreNamed:	[identifier stringByAppendingString:@".sqlite"]];
	[NSManagedObjectContext contextWithStoreCoordinator:[context persistentStoreCoordinator]];
	
#if DEBUG

	do {
	
		NSManagedObjectContext *context = [ds disposableMOC];
		WAUser *user = [ds mainUserInContext:context];
		
		NSParameterAssert([user.identifier isEqual:identifier]);
	
	} while (0);
	
#endif
	
}

@end





@implementation WAAppDelegate (SubclassResponsibility)

- (void) beginNetworkActivity {

	[NSException raise:NSInternalInconsistencyException format:@"Subclass shall implement %s", __PRETTY_FUNCTION__];

}

- (void) endNetworkActivity {

	[NSException raise:NSInternalInconsistencyException format:@"Subclass shall implement %s", __PRETTY_FUNCTION__];

}

- (void) subscribeRemoteNotification {
	
	[NSException raise:NSInternalInconsistencyException format:@"Subclass shall implement %s", __PRETTY_FUNCTION__];

}

- (void) unsubscribeRemoteNotification {
	
	[NSException raise:NSInternalInconsistencyException format:@"Subclass shall implement %s", __PRETTY_FUNCTION__];
	
}

@end
