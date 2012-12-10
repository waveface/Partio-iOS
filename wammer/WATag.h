//
//  WATag.h
//  wammer
//
//  Created by Shen Steven on 12/10/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"


@class WAArticle, WALocation, WATagGroup;

@interface WATag : IRManagedObject

@property (nonatomic, retain) NSString * tagValue;
@property (nonatomic, retain) WAArticle *article;
@property (nonatomic, retain) WATagGroup *tagGroup;
@property (nonatomic, retain) WALocation *location;

@end
