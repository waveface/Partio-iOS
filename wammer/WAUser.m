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

+ (id) transformedValue:(id)aValue fromRemoteKeyPath:(NSString *)aRemoteKeyPath toLocalKeyPath:(NSString *)aLocalKeyPath {

	if ([aLocalKeyPath isEqualToString:@"identifier"])
		return IRWebAPIKitStringValue(aValue);
	
	return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];

}

- (UIImage *) avatar {

	UIImage *primitiveAvatar = [self primitiveValueForKey:@"avatar"];
	
	if (primitiveAvatar)
		return primitiveAvatar;
	
	if (!self.avatarURL)
		return nil;
	
	NSURL *actualAvatarURL = [NSURL URLWithString:self.avatarURL];
	
	if (![actualAvatarURL isFileURL]) {
	
		NSURL *ownURL = [[self objectID] URIRepresentation];
		[[IRRemoteResourcesManager sharedManager] retrieveImageAtURL:actualAvatarURL forced:NO withCompletionBlock: ^ (UIImage *tempImageOrNil) {
		
			if (!tempImageOrNil)
				return;
			
			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
			
			WAUser *foundUser = (WAUser *)[context irManagedObjectForURI:ownURL];
			foundUser.avatar = tempImageOrNil;
			
			NSError *savingError = nil;
			if (![context save:&savingError])
				NSLog(@"Error saving: %@", savingError);
			
		}];
	
	}
	
	return nil;
	
}

@end
