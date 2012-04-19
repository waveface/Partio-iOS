//
//  WADatePickerViewController.h
//  wammer
//
//  Created by Evadne Wu on 4/19/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAPickerPaneViewController.h"

@interface WADatePickerViewController : WAPickerPaneViewController

+ (id) controllerWithCompletion:(void(^)(NSDate *))callback;

@property (strong, nonatomic) NSDate *minDate;
@property (strong, nonatomic) NSDate *maxDate;

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;

- (IBAction) handlePickerValueChanged:(UIDatePicker *)sender;

@end
