//
//  WATutorialViewController.h
//  wammer
//
//  Created by jamie on 7/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WATutorialViewController : UIViewController <UIScrollViewDelegate>

+ (WATutorialViewController *) controllerWithCompletion:(void(^)(void))completion;

@property (nonatomic, readwrite, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, readwrite, weak) IBOutlet UIView *introductionView;
@property (nonatomic, readwrite, weak) IBOutlet UIPageControl *pageControl;
@property (nonatomic, readwrite, weak) IBOutlet UIButton *startButton;

- (IBAction) enterTimeline:(id)sender;

@end
