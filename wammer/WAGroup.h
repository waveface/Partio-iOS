//
//  WAGroup.h
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

@class WAArticle;

@interface WAGroup : IRManagedObject

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSSet *articles;
@end

@interface WAGroup (CoreDataGeneratedAccessors)

- (void)addArticlesObject:(WAArticle *)value;
- (void)removeArticlesObject:(WAArticle *)value;
- (void)addArticles:(NSSet *)values;
- (void)removeArticles:(NSSet *)values;

@end
