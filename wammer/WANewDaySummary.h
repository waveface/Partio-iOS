//
//  WANewDaySummary.h
//  wammer
//
//  Created by kchiu on 13/2/10.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WANewDaySummary : NSObject

@property (nonatomic, strong) NSDate *date;
@property (nonatomic) NSUInteger numOfPhotos;
@property (nonatomic) NSUInteger numOfDocuments;
@property (nonatomic) NSUInteger numOfWebpages;
@property (nonatomic) NSUInteger numOfEvents;

@end
