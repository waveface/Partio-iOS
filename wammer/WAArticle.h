//
//  WAArticle.h
//  wammer
//
//  Created by Shen Steven on 1/25/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

typedef NS_ENUM(NSUInteger, WAArticleType) {
  WAArticleTypeEvent = 0,
  WAArticleTypeImport = 1,
  WAArticleTypeSharedEvent = 2
};

typedef NS_ENUM(NSUInteger, WAEventArticleType) {
  WAEventArticleUnknownType = 0,
  WAEventArticlePhotoType = 1,
  WAEventArticleSharedType = 2
};

@class WAEventDay, WAFile, WAGroup, WALocation, WAPeople, WATag, WATagGroup, WAUser;

@interface WAArticle : IRManagedObject

@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSString * creationDeviceName;
@property (nonatomic, retain) NSNumber * dirty;
@property (nonatomic, retain) NSNumber * draft;
@property (nonatomic, retain) NSNumber * event;
@property (nonatomic, retain) NSNumber * favorite;
@property (nonatomic, retain) NSNumber * hidden;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSDate * modificationDate;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * eventType;
@property (nonatomic, retain) NSString * textAuto;
@property (nonatomic, retain) NSDate * eventStartDate;
@property (nonatomic, retain) NSDate * eventEndDate;
@property (nonatomic, retain) NSSet *checkins;
@property (nonatomic, retain) NSSet *descriptiveTags;
@property (nonatomic, retain) WAEventDay *eventDay;
@property (nonatomic, retain) NSOrderedSet *files;
@property (nonatomic, retain) WAGroup *group;
@property (nonatomic, retain) WALocation *location;
@property (nonatomic, retain) WAUser *owner;
@property (nonatomic, retain) NSSet *people;
@property (nonatomic, retain) WAFile *representingFile;
@property (nonatomic, retain) NSSet *tags;
@end

@interface WAArticle (CoreDataGeneratedAccessors)

- (void)addCheckinsObject:(WALocation *)value;
- (void)removeCheckinsObject:(WALocation *)value;
- (void)addCheckins:(NSSet *)values;
- (void)removeCheckins:(NSSet *)values;

- (void)addDescriptiveTagsObject:(WATagGroup *)value;
- (void)removeDescriptiveTagsObject:(WATagGroup *)value;
- (void)addDescriptiveTags:(NSSet *)values;
- (void)removeDescriptiveTags:(NSSet *)values;

- (void)insertObject:(WAFile *)value inFilesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromFilesAtIndex:(NSUInteger)idx;
- (void)insertFiles:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeFilesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInFilesAtIndex:(NSUInteger)idx withObject:(WAFile *)value;
- (void)replaceFilesAtIndexes:(NSIndexSet *)indexes withFiles:(NSArray *)values;
- (void)addFilesObject:(WAFile *)value;
- (void)removeFilesObject:(WAFile *)value;
- (void)addFiles:(NSOrderedSet *)values;
- (void)removeFiles:(NSOrderedSet *)values;
- (void)addPeopleObject:(WAPeople *)value;
- (void)removePeopleObject:(WAPeople *)value;
- (void)addPeople:(NSSet *)values;
- (void)removePeople:(NSSet *)values;

- (void)addTagsObject:(WATag *)value;
- (void)removeTagsObject:(WATag *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

@end
