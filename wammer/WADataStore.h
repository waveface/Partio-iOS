//
//  WADataStore.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/21/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "CoreData+IRAdditions.h"


@class WAUser;
@interface WADataStore : IRDataStore

+ (WADataStore *) defaultStore;
- (WADataStore *) initWithManagedObjectModel:(NSManagedObjectModel *)model;

- (WAUser *) mainUserInContext:(NSManagedObjectContext *)context;
- (void) setMainUser:(WAUser *)user inContext:(NSManagedObjectContext *)context;

- (NSNumber *) minSequenceNumber;
- (void) setMinSequenceNumber:(NSNumber *)seq;

- (NSNumber *) maxSequenceNumber;
- (void) setMaxSequenceNumber:(NSNumber *)seq;

- (NSNumber *) storageQuota;
- (void) setStorageQuota:(NSNumber *)quota;

- (NSNumber *) storageUsage;
- (void) setStorageUsage:(NSNumber *)usage;

@end

#import "WADataStore+FetchingConveniences.h"

#import "WAFile.h"
#import "WAFile+WAAdditions.h"
#import "WAArticle.h"
#import "WAArticle+WAAdditions.h"
#import "WAGroup.h"
#import "WAUser.h"
#import "WAUser+WAAdditions.h"
#import "WAFilePageElement.h"
#import "WAGroup.h"
#import "WAStorage.h"
#import "WAUser.h"
#import "WAPeople.h"
#import "WATag.h"
#import "WATagGroup.h"
#import "WALocation.h"
