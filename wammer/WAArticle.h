//
//  WAArticle.h
//  wammer
//
//  Created by Evadne Wu on 5/15/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

@class WAComment, WAFile, WAGroup, WAPreview, WAUser;

@interface WAArticle : IRManagedObject

@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSString * creationDeviceName;
@property (nonatomic, retain) NSNumber * draft;
@property (nonatomic, retain) NSNumber * favorite;
@property (nonatomic, retain) NSNumber * hidden;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSDate * modificationDate;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NSOrderedSet *files;
@property (nonatomic, retain) WAGroup *group;
@property (nonatomic, retain) WAUser *owner;
@property (nonatomic, retain) NSSet *previews;
@property (nonatomic, retain) WAFile *representingFile;
@end

@interface WAArticle (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(WAComment *)value;
- (void)removeCommentsObject:(WAComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

//	DO NOT USE
//	- (void)insertObject:(WAFile *)value inFilesAtIndex:(NSUInteger)idx;
//	- (void)removeObjectFromFilesAtIndex:(NSUInteger)idx;
//	- (void)insertFiles:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
//	- (void)removeFilesAtIndexes:(NSIndexSet *)indexes;
//	- (void)replaceObjectInFilesAtIndex:(NSUInteger)idx withObject:(WAFile *)value;
//	- (void)replaceFilesAtIndexes:(NSIndexSet *)indexes withFiles:(NSArray *)values;
//	- (void)addFilesObject:(WAFile *)value;
//	- (void)removeFilesObject:(WAFile *)value;
//	- (void)addFiles:(NSOrderedSet *)values;
//	- (void)removeFiles:(NSOrderedSet *)values;

- (void)addPreviewsObject:(WAPreview *)value;
- (void)removePreviewsObject:(WAPreview *)value;
- (void)addPreviews:(NSSet *)values;
- (void)removePreviews:(NSSet *)values;

@end
