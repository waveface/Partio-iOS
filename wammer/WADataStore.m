//
//  WADataStore.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/21/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WADataStore.h"


NSString * const kMainUserEntityURIString = @"kMainUserEntityURIString";

//	Deprecated, do not use
NSString * const kLastContentSyncDateInTimeIntervalSince1970 = @"kLastContentSyncDateInTimeIntervalSince1970";

NSString * const kLastSyncSuccessDate = @"WALastSyncSuccessDate";
NSString * const kLastNewPostsUpdateDate = @"WALastNewPostsUpdateDate";
NSString * const kLastChangedPostsUpdateDate = @"WALastChangedPostsUpdateDate";


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

+ (NSDateFormatter *) threadTZDateFormatter {
	static NSString * const key = @"-[WADataStore threadTZDateFormatter]";
	NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
	
	NSDateFormatter *df = [dictionary objectForKey:key];
	if (!df) {
		df = [[NSDateFormatter alloc] init];
		df.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSSZ";
		df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
		[dictionary setObject:df forKey:key];
	}
	
	return df;

}

- (NSDate *) dateFromISO8601String:(NSString *)aDateString {

	if (![aDateString isKindOfClass:[NSString class]] || [aDateString length] == 0)
		return nil;

	NSDate *returned = nil;
	NSError *error = nil;
	
	if (![[[self class] threadLocalDateFormatter] getObjectValue:&returned forString:aDateString range:NULL error:&error]){
		if (![[[self class] threadTZDateFormatter] getObjectValue:&returned forString:aDateString range:NULL error:&error]) {
			NSLog(@"%s: %@ -> %@", __PRETTY_FUNCTION__, aDateString, error);
		}
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
	
	@try {
	
		WAUser *user = (WAUser *)[context irManagedObjectForURI:userEntityURI];
		NSParameterAssert([user isKindOfClass:[WAUser class]]);
	
		return user;
		
	} @catch (NSException *e) {
    
		if ([[e name] isEqual:NSObjectInaccessibleException]) {
		
			NSLog(@"%s: %@", __PRETTY_FUNCTION__, e);
			[self setMainUser:nil inContext:context];
			
		}
		
		@throw e;
		
	}
	
	return nil;
		
}

- (void) setMainUser:(WAUser *)user inContext:(NSManagedObjectContext *)context {

	#pragma unused(context)
	
	if (user) {
	
		NSParameterAssert(![[user objectID] isTemporaryID]);

		NSURL *userEntityURI = [[user objectID] URIRepresentation];
		NSString *userEntityURIString = [userEntityURI absoluteString];
		
		[self setMetadata:userEntityURIString forKey:kMainUserEntityURIString];
		
	} else {
	
		[self setMetadata:nil forKey:kMainUserEntityURIString];
		
	}

}

- (NSDate *) lastSyncSuccessDate {

	return [self metadataForKey:kLastSyncSuccessDate];

}

- (void) setLastSyncSuccessDate:(NSDate *)date {

	[self setMetadata:date forKey:kLastSyncSuccessDate];

}

- (NSDate *) lastNewPostsUpdateDate {

	return [self metadataForKey:kLastNewPostsUpdateDate];

}

- (void) setLastNewPostsUpdateDate:(NSDate *)date {

	[self setMetadata:date forKey:kLastNewPostsUpdateDate];

}

- (NSDate *) lastChangedPostsUpdateDate {

	return [self metadataForKey:kLastChangedPostsUpdateDate];

}

- (void) setLastChangedPostsUpdateDate:(NSDate *)date {

	[self setMetadata:date forKey:kLastChangedPostsUpdateDate];

}

@end
