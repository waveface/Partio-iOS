//
//  WATag.h
//  wammer
//
//  Created by Shen Steven on 11/9/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

@class WAArticle, WATagGroup;

@interface WATag : IRManagedObject

@property (nonatomic, retain) NSString * tagValue;
@property (nonatomic, retain) WAArticle *article;
@property (nonatomic, retain) WATagGroup *tagGroup;

@end
