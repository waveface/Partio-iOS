//
//  WAUser.h
//  wammer
//
//  Created by Evadne Wu on 4/19/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

@class WAArticle, WAComment, WAFile, WAGroup, WAPreview;

@interface WAUser : IRManagedObject

@property (nonatomic, retain) id avatar;
@property (nonatomic, retain) NSString * avatarURL;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * nickname;
@property (nonatomic, retain) NSSet *articles;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NSSet *files;
@property (nonatomic, retain) NSSet *groups;
@property (nonatomic, retain) NSSet *previews;
@property (nonatomic, retain) NSSet *storages;
@end

@interface WAUser (CoreDataGeneratedAccessors)

- (void)addArticlesObject:(WAArticle *)value;
- (void)removeArticlesObject:(WAArticle *)value;
- (void)addArticles:(NSSet *)values;
- (void)removeArticles:(NSSet *)values;

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

- (void)addStoragesObject:(NSManagedObject *)value;
- (void)removeStoragesObject:(NSManagedObject *)value;
- (void)addStorages:(NSSet *)values;
- (void)removeStorages:(NSSet *)values;

@end
