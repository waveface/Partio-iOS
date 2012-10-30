//
//  WAFirstUseIntroViewController.h
//  wammer
//
//  Created by kchiu on 12/10/29.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>

@interface WAFirstUseIntroViewController : UIViewController <UIScrollViewDelegate>
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;

- (IBAction)handleChangePage:(id)sender;
@end
