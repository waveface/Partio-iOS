//
//  WAWebStreamViewController.h
//  wammer
//
//  Created by Shen Steven on 12/17/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WADayViewController.h"

@interface WAWebStreamViewController : UIViewController <WADayViewController>

+ (NSFetchRequest *)fetchRequestForWebpageAccessLogsOnDate:(NSDate *)date;

- (id)initWithDate:(NSDate *)date;
- (void)viewControllerInitialAppeareadOnDayView;

@end
