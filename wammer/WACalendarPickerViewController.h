//
//  WACalendarPickerByTypeViewController.h
//  wammer
//
//  Created by Greener Chen on 12/11/21.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "WAArticle.h"
#import "WANavigationController.h"

typedef NS_ENUM(NSInteger, WACalendarPickerStyle) {
	WACalendarPickerStyleTodayCancel,
	WACalendarPickerStyleMenuToday,
	WACalendarPickerStyleInPopover
};

@interface WACalendarPickerViewController : WANavigationController <UITableViewDelegate>

@property (nonatomic, strong) id delegate;

- (id)initWithStyle:(WACalendarPickerStyle)style;

@end
