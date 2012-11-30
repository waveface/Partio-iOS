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

@interface WACalendarPickerViewController : UIViewController <UITableViewDelegate>

typedef void (^callbackBlock) (NSDate *date);

@property (strong, nonatomic) IBOutlet KalViewController *calPicker;
@property (copy, nonatomic) id dataSource;

@property (weak, nonatomic) IBOutlet UIView *backdropView;
@property (weak, nonatomic) IBOutlet UIView *containerView;

- (void) runPresentingAnimationWithCompletion:(void(^)(void))callback;
- (void) runDismissingAnimationWithCompletion:(void(^)(void))callback;

+ (id) controllerWithCompletion:(callbackBlock)callback;

@end
