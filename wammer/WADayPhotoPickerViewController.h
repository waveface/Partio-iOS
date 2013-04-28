//
//  WADayPhotoPickerViewController.h
//  wammer
//
//  Created by Shen Steven on 4/8/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WADayPhotoPickerViewController : UIViewController

- (id) initWithSelectedAssets:(NSArray *)assets;
- (id) initWithSuggestedDateRangeFrom:(NSDate*)from to:(NSDate*)to;
+ (id) viewControllerWithNavigationControllerWrapped;

@property (nonatomic, copy) void (^onNextHandler)(NSArray *selectedAssets);
@property (nonatomic, copy) void (^onCancelHandler)();
@property (nonatomic, strong) NSString *actionButtonLabelText;

@end
