//
//  WAPeople.h
//  wammer
//
//  Created by Shen Steven on 11/9/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"


@class WAArticle;

@interface WAPeople : IRManagedObject

@property (nonatomic, retain) NSString * avatarURL;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) WAArticle *article;

@end
