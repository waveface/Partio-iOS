//
//  WACalendarPickerByTypeViewController.m
//  wammer
//
//  Created by Greener Chen on 12/11/21.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WACalendarPickerViewController.h"
#import "WACalendarPickerDataSource.h"
#import "WAEventViewController.h"
#import "WAAppearance.h"
#import "WASlidingMenuViewController.h"
#import "Kal.h"
#import "WAFileAccessLog.h"
#import "WAAppDelegate_iOS.h"

@interface WACalendarPickerViewController () <KalDelegate>
{
  KalViewController *calPicker;
  id dataSource;
  WAArticle *selectedEvent;
  BOOL origNavibarHidden;
}

@end

@implementation WACalendarPickerViewController

+ (WANavigationController*) wrappedNavigationControllerForViewController:(WACalendarPickerViewController*)vc forStyle:(WACalendarPickerStyle) style{

  WANavigationController *navVC = [[WANavigationController alloc]initWithRootViewController:vc];

  if (style == WACalendarPickerStyleWithCancel) {
	[vc.navigationItem setLeftBarButtonItem:[vc cancelBarButton] animated:YES];
  } else if (style == WACalendarPickerStyleWithMenu) {
	[vc.navigationItem setLeftBarButtonItem:[vc menuBarButton] animated:YES];
  }
  
  return navVC;
}

+ (CGFloat) minimalCalendarWidth {

  return 320.0f;
  
}

- (WACalendarPickerViewController *)initWithFrame:(CGRect)frame selectedDate:(NSDate *)date
{

  self = [super initWithNibName:nil bundle:nil];
  if (self) {
	calPicker = [[KalViewController alloc] initWithSelectedDate:date];
	calPicker.title = NSLocalizedString(@"TITLE_CALENDAR", @"Title of Canlendar");
	calPicker.delegate = self;
	dataSource = [[WACalendarPickerDataSource alloc] init];
	calPicker.dataSource = dataSource;

    calPicker.frame = frame;
	
	self.view.frame = frame;
	[self.view addSubview:calPicker.view];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  }
  
  return self;
  
}


- (void)viewWillAppear:(BOOL)animated
{
  
  [super viewWillAppear:animated];
  
  self.view.backgroundColor = [UIColor whiteColor];
  self.view.layer.cornerRadius = 3.f;
  self.view.clipsToBounds = YES;

  if (self.navigationController) {
	origNavibarHidden = self.navigationController.navigationBarHidden;
	
	self.title = NSLocalizedString(@"SLIDING_MENU_TITLE_CALENDAR", @"CALENDAR");

	[self.navigationController setNavigationBarHidden:NO animated:animated];
	[self.navigationItem setRightBarButtonItem:[self todayBarButton] animated:YES];
	
	UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	self.toolbarItems = @[space, [self handleEventsButton], space, [self handlePhotosButton], space, [self handleDocsButton], space, [self handleWebpagesButton], space];
	[self.navigationController.toolbar setTintColor:[UIColor lightGrayColor]];
	
	// Since toolbar is not useful in date picker mode, we hide it to prevent to be touched
	[self.navigationController setToolbarHidden:YES animated:animated];
	
  }
  
}

- (void) viewWillDisappear:(BOOL)animated {
  
  [super viewWillDisappear:animated];
  
  if (self.navigationController) {
	
	[self.navigationController setNavigationBarHidden:origNavibarHidden animated:animated];
	[self.navigationController setToolbarHidden:YES animated:animated];
	
  }
  
}


- (void)viewDidDisappear:(BOOL)animated {

  [super viewDidDisappear:animated];
  dataSource = nil;
  calPicker = nil;

}

- (UIBarButtonItem *)dismissBarButton
{
  
  __weak WACalendarPickerViewController *wSelf = self;
  return (UIBarButtonItem *)WABarButtonItemWithButton([self cancelUIButton], ^{
	if (wSelf.onDismissBlock)
	  wSelf.onDismissBlock();
  });
  
}

- (UIBarButtonItem *)menuBarButton
{
  __weak WACalendarPickerViewController *wSelf = self;
  return (UIBarButtonItem *)WABarButtonItem([UIImage imageNamed:@"menu"], @"", ^{
	[wSelf.viewDeckController toggleLeftView];
  });
}

- (UIBarButtonItem *)todayBarButton
{
  UIButton *todayButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [todayButton setFrame:CGRectMake(0.f, 0.f, 57.f, 26.f)];
  [todayButton setBackgroundImage:[UIImage imageNamed:@"Kal.bundle/CalBtn"] forState:UIControlStateNormal];
  [todayButton setBackgroundImage:[UIImage imageNamed:@"Kal.bundle/CalBtnPress"] forState:UIControlStateHighlighted];
  [todayButton setTitle:NSLocalizedString(@"CALENDAR_TODAY_BUTTON", "Today button in calendar picker") forState:UIControlStateNormal];
  todayButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
  [todayButton setTitleColor:[UIColor colorWithRed:0.894f green:0.435f blue:0.353f alpha:1.f] forState:UIControlStateNormal];
  todayButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
  todayButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
  [todayButton addTarget:self action:@selector(handleSelectToday) forControlEvents:UIControlEventTouchUpInside];

  return [[UIBarButtonItem alloc] initWithCustomView:todayButton];
}

- (UIButton *)cancelUIButton
{
  UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [cancelButton setFrame:CGRectMake(0, 0, 57, 26)];
  [cancelButton setBackgroundImage:[UIImage imageNamed:@"Kal.bundle/CalBtn"] forState:UIControlStateNormal];
  [cancelButton setBackgroundImage:[UIImage imageNamed:@"Kal.bundle/CalBtnPress"] forState:UIControlStateHighlighted];
  [cancelButton setTitle:NSLocalizedString(@"CALENDAR_CANCEL_BUTTON", "Cancel button in calendar picker") forState:UIControlStateNormal];
  cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
  [cancelButton setTitleColor:[UIColor colorWithRed:0.757f green:0.757f blue:0.757f alpha:1.f] forState:UIControlStateNormal];
  [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
  cancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
  cancelButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	
  return cancelButton;
}

- (UIBarButtonItem *)cancelBarButton
{
  UIButton *cancelButton = [self cancelUIButton];
  [cancelButton addTarget:self action:@selector(handleCancel:) forControlEvents:UIControlEventTouchUpInside];
  
  return [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
}

- (void)handleCancel:(UIButton *)sender
{
  
  if (self.onDismissBlock)
	self.onDismissBlock();
  
}

- (void) kalDidSelectOnDate:(NSDate *)date {
  
  WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
  [appDelegate.slidingMenu.viewDeckController closeLeftView];
  [appDelegate.slidingMenu switchToViewStyle:self.currentViewStyle onDate:date];
  
  if (self.onDismissBlock)
	self.onDismissBlock();
  
}

- (void) handleSelectToday
{
  
  WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
  [appDelegate.slidingMenu.viewDeckController closeLeftView];
  [appDelegate.slidingMenu switchToViewStyle:self.currentViewStyle onDate:[NSDate date]];
  
  if (self.onDismissBlock)
	self.onDismissBlock();

  //	[calPicker showAndSelectDate:[NSDate date]];
}


- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDelegate protocol conformance

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 54;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  selectedEvent = [[dataSource items] objectAtIndex:indexPath.row];
  
  if ([selectedEvent isKindOfClass:[WAArticle class]]) {
	WAEventViewController *eventVC = [WAEventViewController controllerForArticle:selectedEvent];
	
	if (isPad()) {
	  UINavigationController *navC = [[WANavigationController alloc] initWithRootViewController:eventVC];
	  navC.modalPresentationStyle = UIModalPresentationFormSheet;
	  [self presentViewController:navC animated:YES completion:nil];
	  
	} else {
	  
	  if (self.navigationController)
		[self.navigationController pushViewController:eventVC animated:YES];
	  
	}

  }
	
}

#pragma mark - Orientation

- (NSUInteger)supportedInterfaceOrientations
{
	
  if (isPad())
  	return UIInterfaceOrientationMaskAll;
  else
	return UIInterfaceOrientationMaskPortrait;
	
}

- (BOOL)shouldAutorotate
{
	
  return YES;
	
}

#pragma mark - icon buttons

- (UIBarButtonItem*)handleEventsButton
{
  
  __weak WACalendarPickerViewController *wSelf = self;
  NSDate *pickedDate = [[calPicker selectedNSDate] copy];
  return (UIBarButtonItem *)WABarButtonItem([UIImage imageNamed:@"EventsIcon"], @"", ^{
	WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
	[appDelegate.slidingMenu.viewDeckController closeLeftView];
	[appDelegate.slidingMenu switchToViewStyle:WAEventsViewStyle onDate:pickedDate];
	if (wSelf.onDismissBlock)
	  wSelf.onDismissBlock();
  });
	
}

- (UIBarButtonItem*)handlePhotosButton
{

  __weak WACalendarPickerViewController *wSelf = self;
  NSDate *pickedDate = [[calPicker selectedNSDate] copy];
  return (UIBarButtonItem *)WABarButtonItem([UIImage imageNamed:@"PhotosIcon"], @"", ^{
	WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
	[appDelegate.slidingMenu.viewDeckController closeLeftView];
	[appDelegate.slidingMenu switchToViewStyle:WAPhotosViewStyle onDate:pickedDate];
	if (wSelf.onDismissBlock)
	  wSelf.onDismissBlock();
  });
	
}

- (UIBarButtonItem*)handleDocsButton
{
  
  __weak WACalendarPickerViewController *wSelf = self;
  NSDate *pickedDate = [[calPicker selectedNSDate] copy];
  return (UIBarButtonItem*)WABarButtonItem([UIImage imageNamed:@"DocumentsIcon"], @"", ^{
	WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
	[appDelegate.slidingMenu.viewDeckController closeLeftView];
	[appDelegate.slidingMenu switchToViewStyle:WADocumentsViewStyle onDate:pickedDate];
	if (wSelf.onDismissBlock)
	  wSelf.onDismissBlock();
  });

}

- (UIBarButtonItem*)handleWebpagesButton
{
  
  __weak WACalendarPickerViewController *wSelf = self;
  NSDate *pickedDate = [[calPicker selectedNSDate] copy];
  return (UIBarButtonItem*)WABarButtonItem([UIImage imageNamed:@"Webicon"], @"", ^{
	WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
	[appDelegate.slidingMenu.viewDeckController closeLeftView];
	[appDelegate.slidingMenu switchToViewStyle:WAWebpagesViewStyle onDate:pickedDate];
	if (wSelf.onDismissBlock)
	  wSelf.onDismissBlock();

  });
  
}

@end
