//
//  WAFile.m
//  wammer
//
//  Created by Shen Steven on 5/29/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAFile.h"
#import "WAArticle.h"
#import "WACache.h"
#import "WACollection.h"
#import "WAFileAccessLog.h"
#import "WAFileExif.h"
#import "WAFilePageElement.h"
#import "WALocation.h"
#import "WAPhotoDay.h"
#import "WAUser.h"


@implementation WAFile

@dynamic assetURL;
@dynamic codeName;
@dynamic created;
@dynamic creationDeviceIdentifier;
@dynamic dirty;
@dynamic extraSmallThumbnailFilePath;
@dynamic hidden;
@dynamic identifier;
@dynamic importTime;
@dynamic largeThumbnailFilePath;
@dynamic largeThumbnailURL;
@dynamic outdated;
@dynamic remoteFileName;
@dynamic remoteFileSize;
@dynamic remoteRepresentedImage;
@dynamic remoteResourceHash;
@dynamic remoteResourceType;
@dynamic resourceFilePath;
@dynamic resourceType;
@dynamic resourceURL;
@dynamic smallThumbnailFilePath;
@dynamic smallThumbnailURL;
@dynamic text;
@dynamic thumbnail;
@dynamic thumbnailFilePath;
@dynamic thumbnailURL;
@dynamic timestamp;
@dynamic title;
@dynamic webFaviconURL;
@dynamic webTitle;
@dynamic webURL;
@dynamic alreadyRead;
@dynamic accessLogs;
@dynamic articles;
@dynamic caches;
@dynamic collections;
@dynamic coverOfCollection;
@dynamic exif;
@dynamic locationMeta;
@dynamic owner;
@dynamic pageElements;
@dynamic photoDay;
@dynamic representedArticle;

@end
