//
//  WALocation.h
//  wammer
//
//  Created by Shen Steven on 11/9/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"


@class WAArticle;

@interface WALocation : IRManagedObject

@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * zoomLevel;
@property (nonatomic, retain) WAArticle *article;

@end
