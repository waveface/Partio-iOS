//
//  WAUser.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/27/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

#import "IRWebAPIKit.h"

#ifndef __WAUser__
#define __WAUser__
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	#define WAUserImage UIImage
#else
	#define WAUserImage NSImage
#endif
#endif


@interface WAUser : IRManagedObject

@property (nonatomic, retain) WAUserImage * avatar;
@property (nonatomic, retain) NSString * avatarURL;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * nickname;
@property (nonatomic, retain) NSSet *articles;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NSSet *files;

@end

@interface WAUser (CoreDataGeneratedAccessors)

- (void)addArticlesObject:(NSManagedObject *)value;
- (void)removeArticlesObject:(NSManagedObject *)value;
- (void)addArticles:(NSSet *)values;
- (void)removeArticles:(NSSet *)values;

- (void)addCommentsObject:(NSManagedObject *)value;
- (void)removeCommentsObject:(NSManagedObject *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addFilesObject:(NSManagedObject *)value;
- (void)removeFilesObject:(NSManagedObject *)value;
- (void)addFiles:(NSSet *)values;
- (void)removeFiles:(NSSet *)values;

@end
