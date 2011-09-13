//
//  WAOpenGraphElement.h
//  wammer-iOS
//
//  Created by Evadne Wu on 9/8/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"
#import "IRWebAPIKit.h"

@interface WAOpenGraphElement : IRManagedObject

@property (nonatomic, retain) NSString * providerName;
@property (nonatomic, retain) NSString * providerURL;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * thumbnailFilePath;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * url;

+ (IRRemoteResourcesManager *) sharedRemoteResourcesManager;
+ (NSOperationQueue *) remoteResourceHandlingQueue;

@end
