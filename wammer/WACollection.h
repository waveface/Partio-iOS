//
//  WACollection.h
//  wammer
//
//  Created by jamie on 12/11/5.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class WAFile, WAUser;

@interface WACollection : NSManagedObject

@property (nonatomic, retain) NSDate * createDate;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSDate * modifyDate;
@property (nonatomic, retain) NSString * name;
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
