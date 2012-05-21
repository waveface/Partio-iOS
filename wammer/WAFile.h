//
//  WAFile.h
//  wammer
//
//  Created by Evadne Wu on 5/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "CoreData+IRAdditions.h"

@class WAArticle, WAFilePageElement, WAUser;

@interface WAFile : IRManagedObject

@property (nonatomic, retain) NSString * codeName;
@property (nonatomic, retain) NSString * creationDeviceIdentifier;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * largeThumbnailFilePath;
@property (nonatomic, retain) NSString * largeThumbnailURL;
@property (nonatomic, retain) NSString * remoteFileName;
@property (nonatomic, retain) NSNumber * remoteFileSize;
@property (nonatomic, retain) NSString * remoteRepresentedImage;
@property (nonatomic, retain) NSString * remoteResourceHash;
@property (nonatomic, retain) NSString * remoteResourceType;
@property (nonatomic, retain) NSString * resourceFilePath;
@property (nonatomic, retain) NSString * resourceType;
@property (nonatomic, retain) NSString * resourceURL;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) UIImage * thumbnail DEPRECATED_ATTRIBUTE;
@property (nonatomic, retain) NSString * thumbnailFilePath;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * smallThumbnailFilePath;
@property (nonatomic, retain) NSString * smallThumbnailURL;
@property (nonatomic, retain) WAArticle *article;
@property (nonatomic, retain) WAUser *owner;
@property (nonatomic, retain) NSOrderedSet *pageElements;
@property (nonatomic, retain) WAArticle *representedArticle;
@end

@interface WAFile (CoreDataGeneratedAccessors)

- (void)insertObject:(WAFilePageElement *)value inPageElementsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPageElementsAtIndex:(NSUInteger)idx;
- (void)insertPageElements:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePageElementsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPageElementsAtIndex:(NSUInteger)idx withObject:(WAFilePageElement *)value;
- (void)replacePageElementsAtIndexes:(NSIndexSet *)indexes withPageElements:(NSArray *)values;
- (void)addPageElementsObject:(WAFilePageElement *)value;
- (void)removePageElementsObject:(WAFilePageElement *)value;
- (void)addPageElements:(NSOrderedSet *)values;
- (void)removePageElements:(NSOrderedSet *)values;
@end
