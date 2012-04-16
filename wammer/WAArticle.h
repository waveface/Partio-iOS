//
//  WAArticle.h
//  wammer
//
//  Created by Evadne Wu on 4/16/12.
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
@property (nonatomic, retain) NSArray * fileOrder;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSDate * modificationDate;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * hidden;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NSSet *files;
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

- (void)addFilesObject:(WAFile *)value;
- (void)removeFilesObject:(WAFile *)value;
- (void)addFiles:(NSSet *)values;
- (void)removeFiles:(NSSet *)values;

- (void)addPreviewsObject:(WAPreview *)value;
- (void)removePreviewsObject:(WAPreview *)value;
- (void)addPreviews:(NSSet *)values;
- (void)removePreviews:(NSSet *)values;

@end

#import "WAArticle+WAAdditions.h"
