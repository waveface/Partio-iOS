//
//  WANewDayEvent.h
//  wammer
//
//  Created by kchiu on 13/2/10.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WADayEventStyle) {
  WADayEventStyleNone,
  WADayEventStylePhoto,
  WADayEventStyleCheckin
};

@interface WANewDayEvent : NSObject

@property (nonatomic) WADayEventStyle style;
@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSDate *startTime;

@end
