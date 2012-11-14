//
//  WAFile.h
//  wammer
//
//  Created by jamie on 12/11/14.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "CoreData+IRAdditions.h"

@class WAArticle, WACache, WACollection, WAFileExif, WAFilePageElement, WAUser;

@interface WAFile : IRManagedObject

@property (nonatomic, retain) NSString * assetURL;
@property (nonatomic, retain) NSString * codeName;
@property (nonatomic, retain) NSString * creationDeviceIdentifier;
@property (nonatomic, retain) NSNumber * dirty;
@property (nonatomic, retain) NSString * extraSmallThumbnailFilePath;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSDate * importTime;
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
@property (nonatomic, retain) NSString * smallThumbnailFilePath;
@property (nonatomic, retain) NSString * smallThumbnailURL;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) id thumbnail;
@property (nonatomic, retain) NSString * thumbnailFilePath;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * webFaviconURL;
@property (nonatomic, retain) NSString * webTitle;
@property (nonatomic, retain) NSString * webURL;
@property (nonatomic, retain) NSDate * eventTime;
@property (nonatomic, retain) NSSet *articles;
@property (nonatomic, retain) WACollection *belongToCollection;
@property (nonatomic, retain) NSSet *caches;
@property (nonatomic, retain) WAFileExif *exif;
@property (nonatomic, retain) WAUser *owner;
@property (nonatomic, retain) NSOrderedSet *pageElements;
@property (nonatomic, retain) WAArticle *representedArticle;
@end

@interface WAFile (CoreDataGeneratedAccessors)

- (void)addArticlesObject:(WAArticle *)value;
- (void)removeArticlesObject:(WAArticle *)value;
- (void)addArticles:(NSSet *)values;
- (void)removeArticles:(NSSet *)values;

- (void)addCachesObject:(WACache *)value;
- (void)removeCachesObject:(WACache *)value;
- (void)addCaches:(NSSet *)values;
- (void)removeCaches:(NSSet *)values;

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
