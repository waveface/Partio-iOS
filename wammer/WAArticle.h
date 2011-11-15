//
//  WAArticle.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/27/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

@class WAUser, WAGroup;

@interface WAArticle : IRManagedObject

@property (nonatomic, retain) NSString * creationDeviceName;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NSSet *files;
@property (nonatomic, retain) NSSet *previews;
@property (nonatomic, retain) WAGroup *group;
@property (nonatomic, retain) WAUser *owner;

@property (nonatomic, retain) NSArray *fileOrder;
@property (nonatomic, retain) NSNumber *draft;

@end

@interface WAArticle (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(NSManagedObject *)value;
- (void)removeCommentsObject:(NSManagedObject *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addFilesObject:(NSManagedObject *)value;
- (void)removeFilesObject:(NSManagedObject *)value;
- (void)addFiles:(NSSet *)values;
- (void)removeFiles:(NSSet *)values;

- (void)addPreviewsObject:(NSManagedObject *)value;
- (void)removePreviewsObject:(NSManagedObject *)value;
- (void)addPrevies:(NSSet *)values;
- (void)removePreviews:(NSSet *)values;

@end
