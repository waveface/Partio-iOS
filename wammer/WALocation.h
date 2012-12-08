//
//  WALocation.h
//  wammer
//
//  Created by Shen Steven on 12/6/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"


@class WAArticle, WATag;

@interface WALocation : IRManagedObject

@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * zoomLevel;
@property (nonatomic, retain) WAArticle *article;
@property (nonatomic, retain) NSSet *tags;
@end

@interface WALocation (CoreDataGeneratedAccessors)

- (void)addTagsObject:(WATag *)value;
- (void)removeTagsObject:(WATag *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

@end
