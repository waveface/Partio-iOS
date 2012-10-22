//
//  WAOpenGraphElementImage.h
//  wammer
//
//  Created by Evadne Wu on 5/24/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

@class WAOpenGraphElement, WACache;

@interface WAOpenGraphElementImage : IRManagedObject

@property (nonatomic, retain) NSString * imageFilePath;
@property (nonatomic, retain) NSString * imageRemoteURL;
@property (nonatomic, retain) WAOpenGraphElement *owner;
@property (nonatomic, retain) WAOpenGraphElement *representedElement;
@property (nonatomic, retain) WACache *cache;

@end
