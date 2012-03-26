//
//  WADataStore.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/21/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "CoreData+IRAdditions.h"


@interface WADataStore : IRDataStore

+ (WADataStore *) defaultStore;
- (WADataStore *) initWithManagedObjectModel:(NSManagedObjectModel *)model;

- (NSDate *) dateFromISO8601String:(NSString *)aString;
- (NSString *) ISO8601StringFromDate:(NSDate *)date;

@end

#import "WADataStore+FetchingConveniences.h"

#import "WAFile.h"
#import "WAFile+WAAdditions.h"
#import "WAComment.h"
#import "WAArticle.h"
#import "WAArticle+WAAdditions.h"
#import "WAGroup.h"
#import "WAUser.h"
#import "WAPreview.h"
#import "WAOpenGraphElement.h"
#import "WAFilePageElement.h"
#import "WAGroup.h"
#import "WAUser.h"
#import "WAPreview.h"
#import "WAPreview+WAAdditions.h"
#import "WAOpenGraphElement.h"
#import "WAOpenGraphElement+WAAdditions.h"
#import "WAOpenGraphElementImage.h"
#import "WAOpenGraphElementImage+WAAdditions.h"
