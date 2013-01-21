//
//  WASummaryViewController.h
//  wammer
//
//  Created by kchiu on 13/1/21.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WASummaryViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

- (id)initWithDate:(NSDate *)date;

@end
