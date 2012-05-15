//
//  WAAppDelegate.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import "WAAppDelegate_iOS.h"
#else
#import "WAAppDelegate_Mac.h"
#endif


#import "WAAppDelegate.h"
#import "WADefines.h"
#import "WARemoteInterface.h"
#import "WADataStore.h"

#import "IRKeychainManager.h"
#import "IRRelativeDateFormatter.h"

#import "IRRemoteResourcesManager.h"
#import "IRRemoteResourceDownloadOperation.h"
#import "IRWebAPIEngine+ExternalTransforms.h"


@interface WAAppDelegate () <IRRemoteResourcesManagerDelegate>

+ (Class) preferredClusterClass;
- (IRKeychainInternetPasswordItem *) currentKeychainItem;
- (void) configureRemoteResourceDownloadOperation:(IRRemoteResourceDownloadOperation *)anOperation;

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

	__weak WAAppDelegate *nrSelf  = self;
	
	WARegisterUserDefaults();
	
  [IRRelativeDateFormatter sharedFormatter].approximationMaxTokenCount = 1;
	
	[IRRemoteResourcesManager sharedManager].delegate = self;
	[IRRemoteResourcesManager sharedManager].queue.maxConcurrentOperationCount = 4;
	[IRRemoteResourcesManager sharedManager].onRemoteResourceDownloadOperationWillBegin = ^ (IRRemoteResourceDownloadOperation *anOperation) {
		[nrSelf configureRemoteResourceDownloadOperation:anOperation];
	};

}

- (BOOL) hasAuthenticationData {

	NSString *lastAuthenticatedUserIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:kWALastAuthenticatedUserIdentifier];
	NSData *lastAuthenticatedUserTokenKeychainItemData = [[NSUserDefaults standardUserDefaults] dataForKey:kWALastAuthenticatedUserTokenKeychainItem];
	NSString *lastAuthenticatedUserPrimaryGroupIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:kWALastAuthenticatedUserPrimaryGroupIdentifier];
	IRKeychainAbstractItem *lastAuthenticatedUserTokenKeychainItem = nil;
	
	if (!lastAuthenticatedUserTokenKeychainItem) {
		if (lastAuthenticatedUserTokenKeychainItemData) {
			lastAuthenticatedUserTokenKeychainItem = [NSKeyedUnarchiver unarchiveObjectWithData:lastAuthenticatedUserTokenKeychainItemData];
		}
	}
	
	BOOL authenticationInformationSufficient = ([lastAuthenticatedUserTokenKeychainItem.secret length]) && lastAuthenticatedUserIdentifier;
	
	if (authenticationInformationSufficient) {
	
		if (![lastAuthenticatedUserIdentifier isEqualToString:@""])
			[WARemoteInterface sharedInterface].userIdentifier = lastAuthenticatedUserIdentifier;
		
		if (lastAuthenticatedUserTokenKeychainItem.secretString)
			[WARemoteInterface sharedInterface].userToken = lastAuthenticatedUserTokenKeychainItem.secretString;
		
		if (lastAuthenticatedUserPrimaryGroupIdentifier)
			[WARemoteInterface sharedInterface].primaryGroupIdentifier = lastAuthenticatedUserPrimaryGroupIdentifier;
		
	}
  
  if ([[NSUserDefaults standardUserDefaults] boolForKey:kWAUserRequiresReauthentication])
    authenticationInformationSufficient = NO;
	
	return authenticationInformationSufficient;

}

- (BOOL) removeAuthenticationData {

  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kWALastAuthenticatedUserTokenKeychainItem];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kWALastAuthenticatedUserIdentifier];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kWALastAuthenticatedUserPrimaryGroupIdentifier];
  
  [WARemoteInterface sharedInterface].userIdentifier = nil;
  [WARemoteInterface sharedInterface].userToken = nil;
  [WARemoteInterface sharedInterface].primaryGroupIdentifier = nil;
  
  BOOL didEraseAuthData = [[NSUserDefaults standardUserDefaults] synchronize];
	
  return didEraseAuthData;

}

- (IRKeychainInternetPasswordItem *) currentKeychainItem {

  IRKeychainInternetPasswordItem *lastAuthenticatedUserTokenKeychainItem = nil;

  if (!lastAuthenticatedUserTokenKeychainItem) {
    NSData *lastAuthenticatedUserTokenKeychainItemData = [[NSUserDefaults standardUserDefaults] dataForKey:kWALastAuthenticatedUserTokenKeychainItem];
    if (lastAuthenticatedUserTokenKeychainItemData)
      lastAuthenticatedUserTokenKeychainItem = [NSKeyedUnarchiver unarchiveObjectWithData:lastAuthenticatedUserTokenKeychainItemData];
  }
  
  if (!lastAuthenticatedUserTokenKeychainItem)
    lastAuthenticatedUserTokenKeychainItem = [[IRKeychainInternetPasswordItem alloc] initWithIdentifier:@"com.waveface.wammer"];
	
	if (!lastAuthenticatedUserTokenKeychainItem.serverAddress)
		lastAuthenticatedUserTokenKeychainItem.serverAddress = [[NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:kWARemoteEndpointURL]] host];
  
  return lastAuthenticatedUserTokenKeychainItem;
  
}

- (void) updateCurrentCredentialsWithUserIdentifier:(NSString *)userIdentifier token:(NSString *)userToken primaryGroup:(NSString *)primaryGroupIdentifier {

	IRKeychainInternetPasswordItem *keychainItem = [self currentKeychainItem];
	keychainItem.associatedAccountName = userIdentifier;
	keychainItem.secretString = userToken;
	
	if (![keychainItem synchronize])
		NSLog(@"Did not sync!");
	
	NSParameterAssert(keychainItem.persistentReference);
	
	NSData *archivedItemData = [NSKeyedArchiver archivedDataWithRootObject:keychainItem];
	
	[[NSUserDefaults standardUserDefaults] setObject:archivedItemData forKey:kWALastAuthenticatedUserTokenKeychainItem];
	[[NSUserDefaults standardUserDefaults] setObject:userIdentifier forKey:kWALastAuthenticatedUserIdentifier];
	[[NSUserDefaults standardUserDefaults] setObject:primaryGroupIdentifier forKey:kWALastAuthenticatedUserPrimaryGroupIdentifier];
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWAUserRequiresReauthentication];
	[[NSUserDefaults standardUserDefaults] synchronize];

}

- (void) remoteResourcesManager:(IRRemoteResourcesManager *)managed didBeginDownloadingResourceAtURL:(NSURL *)anURL {

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
		
		NSString *constructedURLString = [[NSArray arrayWithObjects:
			
			[replacementScheme stringByAppendingString:@"://"],
			replacementHost,	//	[givenURL host] ? [givenURL host] : @"",
			replacementPort ? [@":" stringByAppendingString:[replacementPort stringValue]] : @"",
			[givenURL path] ? [givenURL path] : @"",
			[givenURL query] ? [@"?" stringByAppendingString:[givenURL query]] : @"",
			[givenURL fragment] ? [@"#" stringByAppendingString:[givenURL fragment]] : @"",
			
		nil] componentsJoinedByString:@""];
		
		NSURL *constructedURL = [NSURL URLWithString:constructedURLString];
		
		return constructedURL;
		
	}
	
	return givenURL;

}

- (void) configureRemoteResourceDownloadOperation:(IRRemoteResourceDownloadOperation *)anOperation {

	NSMutableURLRequest *originalRequest = [anOperation underlyingRequest];
	
	NSURLRequest *transformedRequest = [[WARemoteInterface sharedInterface].engine transformedRequestWithRequest:originalRequest usingMethodName:@"loadedResource"];
		
	originalRequest.URL = transformedRequest.URL;
	originalRequest.allHTTPHeaderFields = transformedRequest.allHTTPHeaderFields;
	originalRequest.HTTPMethod = transformedRequest.HTTPMethod;
	originalRequest.HTTPBodyStream = transformedRequest.HTTPBodyStream;
	originalRequest.HTTPBody = transformedRequest.HTTPBody;

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
			[tentativeUser addComments:otherUser.articles];
			[tentativeUser addFiles:otherUser.articles];
			[tentativeUser addGroups:otherUser.articles];
			[tentativeUser addPreviews:otherUser.articles];
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
		
		NSArray *foundUsers = [WAUser insertOrUpdateObjectsUsingContext:context withRemoteResponse:[NSArray arrayWithObjects:
		
			[NSDictionary dictionaryWithObjectsAndKeys:
			
				identifier, @"user_id",
			
			nil],
		
		nil] usingMapping:nil options:0];
		
		NSCParameterAssert([foundUsers count] == 1);	
		user = [foundUsers lastObject];
		
		[context obtainPermanentIDsForObjects:[NSArray arrayWithObject:user] error:nil];
		
		if ([context save:nil]) {
			[ds setMainUser:user inContext:context];
			[context save:nil];
		}
		
	}
	
	NSParameterAssert([user.identifier isEqual:identifier]);
	
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

@end
