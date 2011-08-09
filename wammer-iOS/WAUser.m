//
//  WAUser.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/27/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "WAUser.h"
#import "WADataStore.h"


@implementation WAUser

@dynamic avatar;
@dynamic avatarURL;
@dynamic email;
@dynamic identifier;
@dynamic nickname;
@dynamic articles;
@dynamic comments;
@dynamic files;

+ (NSString *) keyPathHoldingUniqueValue {

	return @"identifier";

}

+ (BOOL) skipsNonexistantRemoteKey {

	//	Allows piecemeal data patching, by skipping code path that assigns a placeholder value for any missing value
	//	that -configureWithRemoteDictionary: gets
	return YES;
	
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {

	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
			@"avatarURL", @"avatar_url",
			@"identifier", @"id",
			@"nickname", @"nickname",
			@"email", @"email",
		nil];
		
		[mapping retain];
		
	});

	return mapping;

}

+ (IRRemoteResourcesManager *) sharedRemoteResourcesManager {

	static IRRemoteResourcesManager *sharedManager = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
    
		sharedManager = [[IRRemoteResourcesManager alloc] init];
		sharedManager.delegate = (id<IRRemoteResourcesManagerDelegate>)[UIApplication sharedApplication].delegate;
		
		id notificationObject = [[NSNotificationCenter defaultCenter] addObserverForName:MLRemoteResourcesManagerDidRetrieveResourceNotification object:nil queue:[self remoteResourceHandlingQueue] usingBlock:^(NSNotification *aNotification) {
			
			NSURL *representingURL = (NSURL *)[aNotification object];
			NSData *resourceData = [sharedManager resourceAtRemoteURL:representingURL skippingUncachedFile:NO];
			
			if (![resourceData length])
			return;
						
			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			NSArray *matchingObjects = [context executeFetchRequest:((^ {
				
				NSFetchRequest *fr = [[[NSFetchRequest alloc] init] autorelease];
				fr.entity = [WAUser entityDescriptionForContext:context];
				fr.predicate = [NSPredicate predicateWithFormat:@"avatarURL == %@", [representingURL absoluteString]];
				
				return fr;
			
			})()) error:nil];
			
			for (WAUser *matchingObject in matchingObjects)
				matchingObject.avatar = [UIImage imageWithData:resourceData];
			
			[context save:nil];
			
		}];
		
		objc_setAssociatedObject(sharedManager, @"boundNotificationObject", notificationObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC); 

	});
	
	return sharedManager;

}

+ (NSOperationQueue *) remoteResourceHandlingQueue {

	static NSOperationQueue *returnedQueue = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		returnedQueue = [[NSOperationQueue alloc] init];
	});
	
	return returnedQueue;

}

- (UIImage *) avatar {

	UIImage *primitiveAvatar = [self primitiveValueForKey:@"avatar"];
	
	if (primitiveAvatar)
		return primitiveAvatar;
	
	if (!self.avatarURL)
		return nil;
	
	NSURL *actualAvatarURL = [NSURL URLWithString:self.avatarURL];
	
	if (![actualAvatarURL isFileURL])
		[[[self class] sharedRemoteResourcesManager] retrieveResourceAtRemoteURL:actualAvatarURL forceReload:YES];
	
	return nil;
	
}

@end
