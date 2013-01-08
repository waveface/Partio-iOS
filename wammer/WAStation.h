//
//  WAStation.h
//  wammer
//
//  Created by kchiu on 13/1/8.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"

@class WAUser;

@interface WAStation : IRManagedObject

@property (nonatomic, retain) NSString * httpURL;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * wsURL;
@property (nonatomic, retain) WAUser *user;

@end
