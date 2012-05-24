//
//  WAOpenGraphElement.h
//  wammer
//
//  Created by Evadne Wu on 5/24/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

@class WAOpenGraphElementImage, WAPreview;

@interface WAOpenGraphElement : IRManagedObject

@property (nonatomic, retain) NSString * providerDisplayName;
@property (nonatomic, retain) NSString * providerName;
@property (nonatomic, retain) NSString * providerURL;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSOrderedSet *images;
@property (nonatomic, retain) WAPreview *preview;
@property (nonatomic, retain) WAOpenGraphElementImage *representingImage;
@end

@interface WAOpenGraphElement (CoreDataGeneratedAccessors)

//	- (void)insertObject:(WAOpenGraphElementImage *)value inImagesAtIndex:(NSUInteger)idx;
//	- (void)removeObjectFromImagesAtIndex:(NSUInteger)idx;
//	- (void)insertImages:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
//	- (void)removeImagesAtIndexes:(NSIndexSet *)indexes;
//	- (void)replaceObjectInImagesAtIndex:(NSUInteger)idx withObject:(WAOpenGraphElementImage *)value;
//	- (void)replaceImagesAtIndexes:(NSIndexSet *)indexes withImages:(NSArray *)values;
//	- (void)addImagesObject:(WAOpenGraphElementImage *)value;
//	- (void)removeImagesObject:(WAOpenGraphElementImage *)value;
//	- (void)addImages:(NSOrderedSet *)values;
//	- (void)removeImages:(NSOrderedSet *)values;

@end
