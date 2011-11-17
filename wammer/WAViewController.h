//
//  WAViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/10/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAViewController : UIViewController

@property (nonatomic, readwrite, copy) BOOL (^onShouldAutorotateToInterfaceOrientation)(UIInterfaceOrientation toOrientation);
@property (nonatomic, readwrite, copy) void (^onLoadview)(WAViewController *self);
@property (nonatomic, readwrite, copy) void (^onViewWillAppear)(WAViewController *self);
@property (nonatomic, readwrite, copy) void (^onViewDidAppear)(WAViewController *self);
@property (nonatomic, readwrite, copy) void (^onViewWillDisappear)(WAViewController *self);
@property (nonatomic, readwrite, copy) void (^onViewDidDisappear)(WAViewController *self);

@end
