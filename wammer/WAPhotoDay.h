//
//  WAPhotoDay.h
//  wammer
//
//  Created by kchiu on 13/1/31.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreData+IRAdditions.h>

@class WAFile;

@interface WAPhotoDay : IRManagedObject

@property (nonatomic, retain) NSDate * day;
@property (nonatomic, retain) NSSet *files;
@end

@interface WAPhotoDay (CoreDataGeneratedAccessors)

- (void)addFilesObject:(WAFile *)value;
- (void)removeFilesObject:(WAFile *)value;
- (void)addFiles:(NSSet *)values;
- (void)removeFiles:(NSSet *)values;

@end
