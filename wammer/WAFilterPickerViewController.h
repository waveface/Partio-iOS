//
//  WAFilterPickerViewController.h
//  wammer
//
//  Created by Evadne Wu on 4/20/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAPickerPaneViewController.h"

@class NSFetchRequest;

@interface WAFilterPickerViewController : WAPickerPaneViewController <UIPickerViewDataSource, UIPickerViewDelegate>

+ (id) controllerWithCompletion:(void(^)(NSFetchRequest *))callback;

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;

@end
