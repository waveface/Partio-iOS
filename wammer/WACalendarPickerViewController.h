//
//  WACalendarPickerByTypeViewController.h
//  wammer
//
//  Created by Greener Chen on 12/11/21.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "KalViewController.h"
#import "WAArticle.h"
#import "WANavigationController.h"

typedef NS_ENUM(NSInteger, UIBarButtonCalItem) {
	UIBarButtonCalItemMenu,
	UIBarButtonCalItemToday,
	UIBarButtonCalItemCancel
};

@interface WACalendarPickerViewController : WANavigationController <UITableViewDelegate>

- (id)initWithLeftButton:(UIBarButtonCalItem)leftBarButton RightButton:(UIBarButtonCalItem)rightBarButton navBarHidden:(BOOL)hidden;

@end
