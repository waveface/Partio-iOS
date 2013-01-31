//
//  WAWebStreamViewController.h
//  wammer
//
//  Created by Shen Steven on 12/17/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAWebStreamViewController : UIViewController

+ (NSFetchRequest *)fetchRequestForWebpageAccessLogsOnDate:(NSDate *)date;

- (id)initWithDate:(NSDate *)date;

@end
