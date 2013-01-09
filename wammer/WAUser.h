//
//  WAUser.h
//  wammer
//
//  Created by kchiu on 13/1/8.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

@class WAArticle, WACollection, WAComment, WAFile, WAGroup, WAPreview, WAStation, WAStorage;

@interface WAUser : IRManagedObject

@property (nonatomic, retain) id avatar;
@property (nonatomic, retain) NSString * avatarURL;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * nickname;
@property (nonatomic, retain) NSSet *articles;
@property (nonatomic, retain) NSSet *collections;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NSSet *files;
@property (nonatomic, retain) NSSet *groups;
@property (nonatomic, retain) NSSet *previews;
@property (nonatomic, retain) NSSet *storages;
@property (nonatomic, retain) NSSet *stations;
@end

@interface WAUser (CoreDataGeneratedAccessors)

- (void)addArticlesObject:(WAArticle *)value;
- (void)removeArticlesObject:(WAArticle *)value;
- (void)addArticles:(NSSet *)values;
- (void)removeArticles:(NSSet *)values;

- (void)addCollectionsObject:(WACollection *)value;
- (void)removeCollectionsObject:(WACollection *)value;
- (void)addCollections:(NSSet *)values;
- (void)removeCollections:(NSSet *)values;

- (void)addCommentsObject:(WAComment *)value;
- (void)removeCommentsObject:(WAComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addFilesObject:(WAFile *)value;
- (void)removeFilesObject:(WAFile *)value;
- (void)addFiles:(NSSet *)values;
- (void)removeFiles:(NSSet *)values;

- (void)addGroupsObject:(WAGroup *)value;
- (void)removeGroupsObject:(WAGroup *)value;
- (void)addGroups:(NSSet *)values;
- (void)removeGroups:(NSSet *)values;

- (void)addPreviewsObject:(WAPreview *)value;
- (void)removePreviewsObject:(WAPreview *)value;
- (void)addPreviews:(NSSet *)values;
- (void)removePreviews:(NSSet *)values;

- (void)addStoragesObject:(WAStorage *)value;
- (void)removeStoragesObject:(WAStorage *)value;
- (void)addStorages:(NSSet *)values;
- (void)removeStorages:(NSSet *)values;

- (void)addStationsObject:(WAStation *)value;
- (void)removeStationsObject:(WAStation *)value;
- (void)addStations:(NSSet *)values;
- (void)removeStations:(NSSet *)values;

@end
