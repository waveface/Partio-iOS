//
//  WAArticle.m
//  wammer
//
//  Created by Shen Steven on 4/24/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAArticle.h"
#import "WACheckin.h"
#import "WAEventDay.h"
#import "WAFile.h"
#import "WAGroup.h"
#import "WALocation.h"
#import "WAPeople.h"
#import "WATag.h"
#import "WATagGroup.h"
#import "WAUser.h"


@implementation WAArticle

@dynamic creationDate;
@dynamic creationDeviceName;
@dynamic dirty;
@dynamic draft;
@dynamic event;
@dynamic eventEndDate;
@dynamic eventStartDate;
@dynamic eventType;
@dynamic favorite;
@dynamic hidden;
@dynamic identifier;
@dynamic modificationDate;
@dynamic text;
@dynamic textAuto;
@dynamic lastRead;
@dynamic checkins;
@dynamic descriptiveTags;
@dynamic eventDay;
@dynamic files;
@dynamic group;
@dynamic location;
@dynamic owner;
@dynamic people;
@dynamic representingFile;
@dynamic sharingContacts;
@dynamic tags;

@end
