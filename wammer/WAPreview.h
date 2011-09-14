//
//  WAPreview.h
//  wammer-iOS
//
//  Created by Evadne Wu on 9/8/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

#import "IRWebAPIKit.h"

@class WAArticle, WAUser, WAOpenGraphElement;

@interface WAPreview : IRManagedObject

@property (nonatomic, retain) NSString * htmlSynopsis;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) WAArticle *article;
@property (nonatomic, retain) WAOpenGraphElement *graphElement;
@property (nonatomic, retain) WAUser *owner;
@property (nonatomic, retain) NSDate *timestamp;

@end
