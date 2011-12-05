//
//  WAFile.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/27/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

#import "IRWebAPIKit.h"

@class WAArticle, WAUser;

@interface WAFile : IRManagedObject

@property (nonatomic, retain) NSString * codeName;
@property (nonatomic, retain) NSString * creationDeviceIdentifier;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * remoteFileName;
@property (nonatomic, retain) NSNumber * remoteFileSize;
@property (nonatomic, retain) NSString * remoteRepresentedImage;
@property (nonatomic, retain) NSString * remoteResourceHash;
@property (nonatomic, retain) NSString * remoteResourceType;
@property (nonatomic, retain) NSString * resourceFilePath;
@property (nonatomic, retain) NSString * resourceType;
@property (nonatomic, retain) NSString * resourceURL;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) UIImage *thumbnail;	//	Synthesized thumbnail
@property (nonatomic, retain) NSString * thumbnailFilePath;	//	Downloaded canonical (remote) thumbnail
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * title;

@property (nonatomic, retain) WAArticle *article;
@property (nonatomic, retain) WAUser *owner;

@property (nonatomic, readwrite, retain) UIImage *resourceImage;
@property (nonatomic, readwrite, retain) UIImage *thumbnailImage;

@end
