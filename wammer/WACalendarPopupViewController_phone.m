//
//  WACalendarPopupViewController_phone.m
//  wammer
//
//  Created by Shen Steven on 1/21/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WACalendarPopupViewController_phone.h"

@interface WACalendarPopupViewController_phone ()

@property (nonatomic, strong) WANavigationController *wrappedNaviController;
@property (nonatomic, strong) WACalendarPickerViewController *calendarPicker;
@property (nonatomic, copy) void(^completionBlock)(void);
@property (nonatomic, strong) UIButton *tapper;

@end

@implementation WACalendarPopupViewController_phone {
  CGSize screenSize;
  CGSize calSize;
}

- (id) initWithDate:(NSDate *)aDate viewStyle:(WADayViewSupportedStyle)viewStyle completion:(void (^)(void))completion
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.tapper = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tapper.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tapper.frame = CGRectMake(0, 0, 320, 640);
    [self.tapper setBackgroundColor:[UIColor colorWithWhite:0.4 alpha:0.5]];
    [self.tapper addTarget:self action:@selector(tapperTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view  addSubview:self.tapper];
    
    __weak WACalendarPopupViewController_phone *wSelf = self;
    
    screenSize = [[UIScreen mainScreen] bounds].size;
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    screenSize.height -= statusBarSize.height;
    calSize = CGSizeMake(screenSize.width, 370);
    
    CGRect calFrame = CGRectMake(0, screenSize.height, calSize.width, calSize.height);
    self.calendarPicker = [[WACalendarPickerViewController alloc] initWithFrame:(CGRect){0, 0, 320, 370} selectedDate:aDate];
    self.calendarPicker.currentViewStyle = viewStyle;
    self.wrappedNaviController = [WACalendarPickerViewController wrappedNavigationControllerForViewController:self.calendarPicker forStyle:WACalendarPickerStyleWithCancel];
    
    CGRect offscreenFrame = CGRectMake(0, screenSize.height, calSize.width, calSize.height);
    self.calendarPicker.onDismissBlock = ^{
      [UIView animateWithDuration:0.2f animations:^{
        wSelf.wrappedNaviController.view.frame = offscreenFrame;
      } completion:^(BOOL finished) {
        if (completion)
	completion();
      }];
    };
    self.wrappedNaviController.view.frame = calFrame;
    [self addChildViewController:self.wrappedNaviController];
    [self.view addSubview:self.wrappedNaviController.view];
    [self.view bringSubviewToFront:self.wrappedNaviController.view];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.completionBlock = completion;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view.
}

- (void) viewDidAppear:(BOOL)animated {
  
  [super viewDidAppear:animated];
  
  [UIView animateWithDuration:0.2f animations:^{
    self.wrappedNaviController.view.frame = CGRectMake(0, screenSize.height-calSize.height, calSize.width, calSize.height);
  } completion:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [self.wrappedNaviController willMoveToParentViewController:nil];
  [self.wrappedNaviController removeFromParentViewController];
  [self.wrappedNaviController.view removeFromSuperview];
  [self.wrappedNaviController didMoveToParentViewController:nil];
  self.wrappedNaviController =nil;
  [self.tapper removeFromSuperview];
  self.tapper = nil;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void) dealloc {
  self.calendarPicker = nil;
  self.wrappedNaviController = nil;
}

- (BOOL) shouldAutorotate {
  return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

- (void) tapperTapped:(id)sender {
  
  __weak WACalendarPopupViewController_phone *wSelf = self;
  [UIView animateWithDuration:0.2f animations:^{
    
    wSelf.wrappedNaviController.view.frame = CGRectMake(0, screenSize.height, calSize.width, calSize.height);
    
  } completion:^(BOOL finished) {
    
    if (wSelf.completionBlock)
      wSelf.completionBlock();
    
  }];
  
}

@end
