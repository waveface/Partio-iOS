//
//  WADataStore.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/21/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "CoreData+IRAdditions.h"

#import "WAFile.h"
#import "WAComment.h"
#import "WAArticle.h"
#import "WAGroup.h"
#import "WAUser.h"
#import "WAPreview.h"
#import "WAOpenGraphElement.h"
#import "WAFilePageElement.h"

@interface WADataStore : IRDataStore

+ (WADataStore *) defaultStore;
- (WADataStore *) initWithManagedObjectModel:(NSManagedObjectModel *)model;

- (NSDate *) dateFromISO8601String:(NSString *)aString;

@end

#import "WADataStore+FetchingConveniences.h"