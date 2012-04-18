//
//  WADataStore.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/21/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WADataStore.h"


NSString * const kMainUserEntityURIString = @"kMainUserEntityURIString";
NSString * const kLastContentSyncDateInTimeIntervalSince1970 = @"kLastContentSyncDateInTimeIntervalSince1970";


@interface WADataStore ()

+ (NSDateFormatter *) threadLocalDateFormatter;

@end

@implementation WADataStore

+ (WADataStore *) defaultStore {
	
	return (WADataStore *)[super defaultStore];
	
}

- (WADataStore *) initWithManagedObjectModel:(NSManagedObjectModel *)model {
	
	return (WADataStore *)[super initWithManagedObjectModel:model];
	
}

- (NSManagedObjectModel *) defaultManagedObjectModel {

	return [[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"WAModel" withExtension:@"momd"]];

}

+ (NSDateFormatter *) threadLocalDateFormatter {

	static NSString * const key = @"-[WADataStore threadLocalDateFormatter]";
	NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
	
	NSDateFormatter *df = [dictionary objectForKey:key];
	if (!df) {
		df = [[NSDateFormatter alloc] init];
		df.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
		df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
		df.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
		[dictionary setObject:df forKey:key];
	}
	
	return df;

}

- (NSDate *) dateFromISO8601String:(NSString *)aValue {

	if (![aValue isKindOfClass:[NSString class]])
		return nil;

	NSDate *returned = nil;
	NSError *error = nil;
	
	if (![[[self class] threadLocalDateFormatter] getObjectValue:&returned forString:aValue range:NULL error:&error]){
		NSLog(@"Error parsing date %@", error);
	}
	
	return returned;

}

- (NSString *) ISO8601StringFromDate:(NSDate *)date {

	return [[[self class] threadLocalDateFormatter] stringFromDate:date];

}

- (WAUser *) mainUserInContext:(NSManagedObjectContext *)context {

	NSDictionary *metadata = [self metadata];
	NSString *userEntityURIString = [metadata objectForKey:kMainUserEntityURIString];
	NSURL *userEntityURI = [NSURL URLWithString:userEntityURIString];
	
	if (!userEntityURI)
		return nil;
		
	WAUser *user = (WAUser *)[context irManagedObjectForURI:userEntityURI];
	NSParameterAssert([user isKindOfClass:[WAUser class]]);
	
	return user;
	
}

- (void) setMainUser:(WAUser *)user inContext:(NSManagedObjectContext *)context {

	#pragma unused(context)
	
	NSParameterAssert(user);
	NSParameterAssert(![[user objectID] isTemporaryID]);

	NSMutableDictionary *metadata = [[self metadata] mutableCopy];
	NSURL *userEntityURI = [[user objectID] URIRepresentation];
	NSString *userEntityURIString = [userEntityURI absoluteString];
	
	[metadata setObject:userEntityURIString forKey:kMainUserEntityURIString];
	
	[self setMetadata:metadata];

}

- (NSDate *) lastContentSyncDate {

	NSDictionary *metadata = [self metadata];
	NSNumber *timeInterval = [metadata objectForKey:kLastContentSyncDateInTimeIntervalSince1970];
	if (!timeInterval)
		return nil;
	
	return [NSDate dateWithTimeIntervalSince1970:[timeInterval doubleValue]];

}

- (void) setLastContentSyncDate:(NSDate *)date {

	NSMutableDictionary *metadata = [[self metadata] mutableCopy];
	
	[metadata setObject:[NSNumber numberWithDouble:[date timeIntervalSince1970]] forKey:kLastContentSyncDateInTimeIntervalSince1970];
	
	[self setMedatata:metadata];

}

- (NSDictionary *) metadata {

	NSPersistentStoreCoordinator *psc = self.persistentStoreCoordinator;
	NSArray *stores = psc.persistentStores;
	
	if (![stores count])
		return nil;
	
	NSPersistentStore *firstStore = [stores objectAtIndex:0];
	NSDictionary *metadata = [psc metadataForPersistentStore:firstStore];
	
	return metadata;
	
}

- (void) setMetadata:(NSDictionary *)metadata {

	NSPersistentStoreCoordinator *psc = self.persistentStoreCoordinator;
	NSArray *stores = psc.persistentStores;
	
	if (![stores count])
		return;
	
	NSPersistentStore *firstStore = [stores objectAtIndex:0];
	
	[psc setMetadata:metadata forPersistentStore:firstStore];
	
	NSManagedObjectContext *context = [self disposableMOC];
	[context save:nil];

}

@end
