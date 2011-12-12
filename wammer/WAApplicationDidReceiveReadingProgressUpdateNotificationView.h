//
//  WAApplicationDidReceiveReadingProgressUpdateNotificationView.h
//  wammer
//
//  Created by Evadne Wu on 12/12/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAApplicationDidReceiveReadingProgressUpdateNotificationView : UIView

+ (WAApplicationDidReceiveReadingProgressUpdateNotificationView *) viewFromNib;

@property (retain, nonatomic) IBOutletCollection(UILabel) NSArray *localizableLabels;

- (IBAction) handleAction:(id)sender;
- (IBAction) handleClear:(id)sender;

@property (nonatomic, readwrite, copy) void (^onAction)();
@property (nonatomic, readwrite, copy) void (^onClear)();

- (void) enqueueAnimationForVisibility:(BOOL)willBeVisible completion:(void(^)(BOOL didFinish))aBlock;

@end
