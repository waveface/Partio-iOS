//
//  WAFile.h
//  wammer
//
//  Created by Evadne Wu on 1/9/12.
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
@property (nonatomic, retain) id pageElementOrder;
@property (nonatomic, retain) NSString * remoteFileName;
@property (nonatomic, retain) NSNumber * remoteFileSize;
@property (nonatomic, retain) NSString * remoteRepresentedImage;
@property (nonatomic, retain) NSString * remoteResourceHash;
@property (nonatomic, retain) NSString * remoteResourceType;
@property (nonatomic, retain) NSString * resourceFilePath;
@property (nonatomic, retain) NSString * resourceType;
@property (nonatomic, retain) NSString * resourceURL;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) id thumbnail;
@property (nonatomic, retain) NSString * thumbnailFilePath;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) WAArticle *article;
@property (nonatomic, retain) WAUser *owner;
@property (nonatomic, retain) NSSet *pageElements;
@end

@interface WAFile (CoreDataGeneratedAccessors)

- (void)addPageElementsObject:(WAFilePageElement *)value;
- (void)removePageElementsObject:(WAFilePageElement *)value;
- (void)addPageElements:(NSSet *)values;
- (void)removePageElements:(NSSet *)values;

@end

#import "WAFile+WAAdditions.h"
