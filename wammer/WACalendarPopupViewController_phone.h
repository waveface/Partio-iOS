//
//  WACalendarPopupViewController_phone.h
//  wammer
//
//  Created by Shen Steven on 1/21/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WACalendarPickerViewController.h"
#import "WADayViewController.h"

@interface WACalendarPopupViewController_phone : UIViewController

- (id) initWithDate:(NSDate *)aDate viewStyle:(WADayViewSupportedStyle)viewStyle completion:(void(^)(void))completion;

@end
