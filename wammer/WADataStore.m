//
//  WADataStore.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/21/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WADataStore.h"


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

@end
