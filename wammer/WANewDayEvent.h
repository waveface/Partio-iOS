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
  WADayEventStyleOnePhoto,
  WADayEventStyleTwoPhotos,
  WADayEventStyleThreePhotos,
  WADayEventStyleFourPhotos,
  WADayEventStyleCheckin
};

@class WAArticle;
@interface WANewDayEvent : NSObject

@property (nonatomic, strong) WAArticle *representingArticle;
@property (nonatomic) WADayEventStyle style;
@property (nonatomic, strong) NSMutableDictionary *images;
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) NSString *eventDescription;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSMutableArray *imageLoadingOperations;

- (id)initWithArticle:(WAArticle *)anArticle date:(NSDate *)aDate;
- (void)loadImages;
- (void)unloadImages;

@end
