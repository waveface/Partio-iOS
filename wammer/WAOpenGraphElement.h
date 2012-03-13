//
//  WAOpenGraphElement.h
//  wammer
//
//  Created by Evadne Wu on 3/1/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

@class WAOpenGraphElementImage, WAPreview;

@interface WAOpenGraphElement : IRManagedObject

@property (nonatomic, retain) NSArray * imageOrder;
@property (nonatomic, retain) NSString * providerDisplayName;
@property (nonatomic, retain) NSString * providerName;
@property (nonatomic, retain) NSString * providerURL;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSURL * primaryImageURI;
@property (nonatomic, retain) NSSet * images;
@property (nonatomic, retain) WAPreview *preview;
@end

@interface WAOpenGraphElement (CoreDataGeneratedAccessors)

- (void)addImagesObject:(WAOpenGraphElementImage *)value;
- (void)removeImagesObject:(WAOpenGraphElementImage *)value;
- (void)addImages:(NSSet *)values;
- (void)removeImages:(NSSet *)values;

@end
