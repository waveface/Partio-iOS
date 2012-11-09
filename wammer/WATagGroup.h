//
//  WATagGroup.h
//  wammer
//
//  Created by Shen Steven on 11/9/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

@class WAArticle, WATag;

@interface WATagGroup : IRManagedObject

@property (nonatomic, retain) NSString * leadingString;
@property (nonatomic, retain) WAArticle *article;
@property (nonatomic, retain) NSSet *tags;
@end

@interface WATagGroup (CoreDataGeneratedAccessors)

- (void)addTagsObject:(WATag *)value;
- (void)removeTagsObject:(WATag *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

@end
