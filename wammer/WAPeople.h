//
//  WAPeople.h
//  wammer
//
//  Created by Shen Steven on 6/4/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

@class WAArticle, WAFile;

@interface WAPeople : IRManagedObject

@property (nonatomic, retain) NSString * avatarURL;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * fbID;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * state;
@property (nonatomic, retain) WAArticle *article;
@property (nonatomic, retain) NSSet *files;
@property (nonatomic, retain) NSSet *sharedArticles;
@end

@interface WAPeople (CoreDataGeneratedAccessors)

- (void)addFilesObject:(WAFile *)value;
- (void)removeFilesObject:(WAFile *)value;
- (void)addFiles:(NSSet *)values;
- (void)removeFiles:(NSSet *)values;

- (void)addSharedArticlesObject:(WAArticle *)value;
- (void)removeSharedArticlesObject:(WAArticle *)value;
- (void)addSharedArticles:(NSSet *)values;
- (void)removeSharedArticles:(NSSet *)values;

@end
