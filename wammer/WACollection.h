//
//  WACollection.h
//  wammer
//
//  Created by Shen Steven on 12/25/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreData+IRAdditions.h>

@class WAFile, WAUser;

@interface WACollection : IRManagedObject

@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * isHidden;
@property (nonatomic, retain) NSNumber * isSmart;
@property (nonatomic, retain) NSDate * modificationDate;
@property (nonatomic, retain) NSNumber * sequenceNumber;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) WAFile *cover;
@property (nonatomic, retain) WAUser *creator;
@property (nonatomic, retain) NSOrderedSet *files;
@end

@interface WACollection (CoreDataGeneratedAccessors)

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
@end
