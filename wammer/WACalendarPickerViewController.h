//
//  WACalendarPickerByTypeViewController.h
//  wammer
//
//  Created by Greener Chen on 12/11/21.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "WADayViewController.h"
#import "WAArticle.h"
#import "WANavigationController.h"

typedef void (^dismissBlock)(void);

typedef NS_ENUM(NSInteger, WACalendarPickerStyle) {
  WACalendarPickerStyleNormal,  
  WACalendarPickerStyleWithCancel,
  WACalendarPickerStyleWithMenu,
};

@interface WACalendarPickerViewController : UIViewController <UITableViewDelegate>

@property (nonatomic, copy) dismissBlock onDismissBlock;
@property (nonatomic, assign) WADayViewSupportedStyle currentViewStyle;

+ (CGFloat) minimalCalendarWidth;
+ (WANavigationController*) wrappedNavigationControllerForViewController:(WACalendarPickerViewController*)vc forStyle:(WACalendarPickerStyle) style;
- (WACalendarPickerViewController *)initWithFrame:(CGRect)frame selectedDate:(NSDate *)date;

@end
