//
//  WAComment.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/27/11.
//  Copyright (c) 2011 Waveface Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

@class WAArticle, WAUser;

@interface WAComment : IRManagedObject

@property (nonatomic, retain) NSString * creationDeviceName;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) WAArticle *article;
@property (nonatomic, retain) WAUser *owner;

@end
