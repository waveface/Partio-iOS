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
- (void) selectAllInSection:(NSUInteger)section;
- (void) deselectAllInSection:(NSUInteger)section;

@property (nonatomic, copy) void (^onNextHandler)(NSArray *selectedAssets);
@property (nonatomic, copy) void (^onCancelHandler)();
@property (nonatomic, strong) NSString *actionButtonLabelText;
@property (nonatomic, assign) BOOL allowTitleEditing;
@property (nonatomic, strong) NSString *titleText;

@end
