//
//  WAUser+WAAdditions.m
//  wammer
//
//  Created by Evadne Wu on 4/19/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAUser+WAAdditions.h"
#import "WADataStore.h"

@implementation WAUser (WAAdditions)

- (WAStorage *) mainStorage {

	for (WAStorage *storage in self.storages)
		if ([storage.displayName isEqualToString:@"waveface"])
			return storage;
	
	return nil;

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
		[[IRRemoteResourcesManager sharedManager] retrieveImageAtURL:actualAvatarURL forced:NO withCompletionBlock: ^ (IRRemoteResourcesManagerImage *tempImageOrNil) {
		
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

+ (BOOL) automaticallyNotifiesObserversForKey:(NSString *)key {

	return YES;

}

@end
