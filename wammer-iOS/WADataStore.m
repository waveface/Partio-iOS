//
//  WADataStore.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/21/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WADataStore.h"

@implementation WADataStore

+ (WADataStore *) defaultStore {
	
	return (WADataStore *)[super defaultStore];
	
}

- (WADataStore *) initWithManagedObjectModel:(NSManagedObjectModel *)model {
	
	return (WADataStore *)[super initWithManagedObjectModel:model];
	
}

- (NSManagedObjectModel *) defaultManagedObjectModel {

	return [[[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"WAModel" withExtension:@"momd"]] autorelease];

}

- (NSDate *) dateFromISO8601String:(NSString *)aValue {

	static NSDateFormatter *sharedFormatter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedFormatter = [[NSDateFormatter alloc] init];
		sharedFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
		sharedFormatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
		sharedFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
	});
	
	if ([aValue isKindOfClass:[NSString class]]) {
		NSDate *returned = nil;
		NSError *error = nil;
		if (![sharedFormatter getObjectValue:&returned forString:aValue range:NULL error:&error]){
			NSLog(@"Error parsing date %@", error);
		}
		NSParameterAssert(returned);
		return returned;
	}
		
	return nil;

}

@end
