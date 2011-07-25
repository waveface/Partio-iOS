//
//  WADataStore.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/21/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "CoreData+IRAdditions.h"

@interface WADataStore : IRDataStore

+ (WADataStore *) defaultStore;
- (WADataStore *) initWithManagedObjectModel:(NSManagedObjectModel *)model;

@end
