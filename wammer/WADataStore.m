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

NSString * const kMinSequenceNumber = @"WAMinSequenceNumber";
NSString * const kMaxSequenceNumber = @"WAMaxSequenceNumber";
NSString * const kStorageQuota = @"WAStorageQuota";
NSString * const kStorageUsage = @"WAStorageUsage";

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
  
  NSDateFormatter *df = dictionary[key];
  if (!df) {
    df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    df.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    dictionary[key] = df;
  }
  
  return df;
  
}

+ (NSDateFormatter *) threadTZDateFormatter {
  static NSString * const key = @"-[WADataStore threadTZDateFormatter]";
  NSMutableDictionary *dictionary = [[NSThread currentThread] threadDictionary];
  
  NSDateFormatter *df = dictionary[key];
  if (!df) {
    df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSSZ";
    df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dictionary[key] = df;
  }
  
  return df;
  
}

- (WAUser *) mainUserInContext:(NSManagedObjectContext *)context {
  
  NSDictionary *metadata = [self metadata];
  NSString *userEntityURIString = metadata[kMainUserEntityURIString];
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

- (NSNumber *) minSequenceNumber {
  
  return [self metadataForKey:kMinSequenceNumber];

}

- (void)setMinSequenceNumber:(NSNumber *)seq {

  [self setMetadata:seq forKey:kMinSequenceNumber];

}

- (NSNumber *) maxSequenceNumber {
	
  return [self metadataForKey:kMaxSequenceNumber];

}

- (void) setMaxSequenceNumber:(NSNumber *)seq {

	if ([seq compare:[self metadataForKey:kMaxSequenceNumber]]==NSOrderedDescending) {
		[self setMetadata:seq forKey:kMaxSequenceNumber];
	}

}

- (NSNumber *) storageQuota {

  return [self metadataForKey:kStorageQuota];

}

- (void)setStorageQuota:(NSNumber *)quota {

  [self setMetadata:quota forKey:kStorageQuota];

}

- (NSNumber *)storageUsage {

  return [self metadataForKey:kStorageUsage];

}

- (void)setStorageUsage:(NSNumber *)usage {

  [self setMetadata:usage forKey:kStorageUsage];

}

@end
