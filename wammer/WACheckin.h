//
//  WACheckin.h
//  wammer
//
//  Created by Shen Steven on 4/24/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+IRAdditions.h"



@interface WACheckin : IRManagedObject

@property (nonatomic, retain) NSDate * createDate;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * taggedUsers;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;

@end
