//
//  WACollection.h
//  wammer
//
//  Created by jamie on 12/11/2.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class WAFile, WAUser;

@interface WACollection : NSManagedObject

@property (nonatomic, retain) NSDate * createDate;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSDate * modifyDate;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) WAUser *creator;
@property (nonatomic, retain) WAFile *files;

@end
