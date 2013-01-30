//
//  WASlidingMenuViewController.m
//  wammer
//
//  Created by Shen Steven on 9/16/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WASlidingMenuViewController.h"
#import "WAAppDelegate.h"
#import "WADefines.h"
#import "IRAction.h"
#import "IRAlertView.h"
#import "IRBarButtonItem.h"
#import "WADayViewController.h"
#import "WANavigationController.h"
#import "WATimelineViewController.h"
#import "WACalendarPickerViewController.h"
#import "WACalendarPopupViewController_phone.h"
#import "WAUserInfoViewController.h"
#import "WAOverlayBezel.h"
#import "WADataStore.h"
#import <Foundation/Foundation.h>
#import "WAPhotoStreamViewController.h"
#import "WAAppDelegate_iOS.h"
#import "WAStatusBar.h"
#import "WACalendarPickerViewController.h"
#import "WADocumentStreamViewController.h"
#import "WAWebStreamViewController.h"
#import "WACollectionViewController.h"
#import "WASyncManager.h"
#import "WAFetchManager.h"
#import <QuartzCore/QuartzCore.h>
#import "WASummaryViewController.h"

static NSString * kWASlidingMenuViewControllerKVOContext = @"WASlidingMenuViewControllerKVOContext";

@interface WASlidingMenuViewController () <UIPopoverControllerDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) WAUser *user;
@property (nonatomic, strong) UITableViewCell *userCell;
@property (nonatomic, strong) UIButton *calendarButton;
@property (nonatomic, strong) UIPopoverController *calendarPopoverForIPad;

@property (nonatomic, strong) WAStatusBar *statusBar;

@end

@implementation WASlidingMenuViewController

+ (CGFloat) ledgeSize {
  
  if (isPad()) {
    
    return [WACalendarPickerViewController minimalCalendarWidth];
    
  } else {
    
    return 200.0f;
    
  }
  
}

+ (UIViewController *)dayViewControllerForViewStyle:(WADayViewSupportedStyle)viewStyle {
  
  NSAssert1(((viewStyle==WAEventsViewStyle) || (viewStyle == WAPhotosViewStyle) || (viewStyle == WADocumentsViewStyle) || (viewStyle == WAWebpagesViewStyle)), @"Unsupported view style: %d", viewStyle);
  
  UIViewController *swVC = nil;
  if (viewStyle == WAEventsViewStyle) {
    swVC = [[WASummaryViewController alloc] initWithDate:nil];
  } else {
    swVC = [[WADayViewController alloc] initWithStyle:viewStyle];
  }
  WANavigationController *navVC = [[WANavigationController alloc] initWithRootViewController:swVC];
  
  swVC.view.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];

  if (viewStyle == WAPhotosViewStyle) {
    [swVC.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"photoStreamNavigationBar"] forBarMetrics:UIBarMetricsDefault];
    swVC.view.backgroundColor = [UIColor colorWithWhite:0.16f alpha:1.0f];
    [swVC.navigationController.navigationBar setShadowImage:nil];
  }
  
  return navVC;
}

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self.tableView setBackgroundColor:[UIColor colorWithWhite:0.3f alpha:1.0f]];
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  
}

- (void)dealloc
{
  [self.user removeObserver:self forKeyPath:@"avatar" context:&kWASlidingMenuViewControllerKVOContext];
  [self.user removeObserver:self forKeyPath:@"nickname" context:&kWASlidingMenuViewControllerKVOContext];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void) handleUserInfo {
  
  [self.viewDeckController closeLeftView];
  
  WANavigationController *navC = nil;
  WAUserInfoViewController *userInfoVC = [WAUserInfoViewController controllerWithWrappingNavController:&navC];
  
  __weak WASlidingMenuViewController *wSelf = self;
  
  userInfoVC.navigationItem.leftBarButtonItem = WABarButtonItem([UIImage imageNamed:@"menu"], @"", ^{
    [wSelf.viewDeckController toggleLeftView];
  });
  
  [self.viewDeckController setCenterController:navC];
  
}

- (NSManagedObjectContext *) managedObjectContext {
  
  if (_managedObjectContext)
    return _managedObjectContext;
  
  _managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
  return _managedObjectContext;
  
}

- (WAUser *) user {
  
  if (_user)
    return _user;
  
  _user = [[WADataStore defaultStore] mainUserInContext:self.managedObjectContext];
  return _user;
  
}

- (void)registerObserver
{
  NSKeyValueObservingOptions options = NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew;
  
  [self.user addObserver:self forKeyPath:@"avatar" options:options context:&kWASlidingMenuViewControllerKVOContext];
  [self.user addObserver:self forKeyPath:@"nickname" options:options context:&kWASlidingMenuViewControllerKVOContext];
  
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  
  id newValue = [change objectForKey:NSKeyValueChangeNewKey];
  
  if ([keyPath isEqual:@"avatar"]) {
    
    UIImage *defaultAvatar = [UIImage imageNamed:@"TempAvatar"];
    UIImageView *avatar = [[UIImageView alloc] initWithImage:defaultAvatar];
    avatar.frame = CGRectMake(7.5f, 7.5f, defaultAvatar.size.width, defaultAvatar.size.height);
    avatar.layer.cornerRadius = 5.f;
    avatar.clipsToBounds = YES;
    avatar.image = ([newValue isKindOfClass:[NSNull class]])? defaultAvatar: (UIImage *)newValue;
    [_userCell.contentView addSubview:avatar];
  }
  
  if ([keyPath isEqual:@"nickname"]) {
    
    if ([newValue isKindOfClass:[NSNull class]]) {
      return;
    }
    
    UILabel *nameLabel = [[UILabel alloc] init];
    [nameLabel setFrame:CGRectMake(50, 7, 200, 30)];
    [nameLabel setText:(NSString *)newValue];
    [nameLabel setTextColor:[UIColor whiteColor]];
    [nameLabel setFont:[UIFont fontWithName:NSLocalizedString(@"SLIDING_MENU_FONTNAME", @"Font name of the sliding menu") size:18.0]];
    [nameLabel setBackgroundColor:[UIColor colorWithRed:0.31f green:0.31f blue:0.31f alpha:1.f]];
    [_userCell.contentView addSubview:nameLabel];
    
  }
  
  __weak WASlidingMenuViewController *wSelf = self;
  
  if ([keyPath isEqualToString:@"isFetching"] || [keyPath isEqualToString:@"isSyncing"]) {
    BOOL isFetching = NO;
	BOOL isSyncing = NO;
	
	if ([keyPath isEqualToString:@"isFetching"])
	  isFetching = [change[NSKeyValueChangeNewKey] boolValue];
	if ([keyPath isEqualToString:@"isSyncing"])
	  isSyncing = [change[NSKeyValueChangeNewKey] boolValue];
	
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

	  if (!wSelf.statusBar && [[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground) {
		wSelf.statusBar = [[WAStatusBar alloc] initWithFrame:CGRectZero];
	  }
	  WASyncManager *syncManager = [(WAAppDelegate_iOS *)AppDelegate() syncManager];
	  WAFetchManager *fetchManager = [(WAAppDelegate_iOS *)AppDelegate() fetchManager];

	  if (isSyncing) {
		if (syncManager.isSyncFail) {
		  [wSelf.statusBar showSyncFailWithDismissBlock:^{
			wSelf.statusBar = nil;
		  }];
		} else if (syncManager.needingSyncFilesCount > 0) {
		  [wSelf.statusBar showPhotoSyncingWithSyncedFilesCount:syncManager.syncedFilesCount needingSyncFilesCount:syncManager.needingSyncFilesCount];
		} else if (syncManager.needingImportFilesCount > 0) {
		  [wSelf.statusBar showPhotoImportingWithImportedFilesCount:syncManager.importedFilesCount needingImportFilesCount:syncManager.needingImportFilesCount];
		}
	  }
	  
      if (isFetching || isSyncing) {
        [wSelf.statusBar startDataExchangeAnimation];
      }
	  
	  if (!syncManager.isSyncing && !fetchManager.isFetching) { // no more sync, neither fetch
		if (wSelf.statusBar)
		  [wSelf.statusBar stopDataExchangeAnimation];

		[wSelf.statusBar showSyncCompleteWithDissmissBlock:^{
		  wSelf.statusBar = nil;
		}];
      }
	  
    }];
  }
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  // Return the number of sections.
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return 7;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.row == 0) {
    return 44;
  }
  
  return 54;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.row == 0) {
    if (_userCell) {
      return _userCell;
    }
    
    _userCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UserIdentifier"];
    _userCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    
    [self registerObserver];
    
    return _userCell;
    
  }
  
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
  }
 
  for (UIView *aView in cell.subviews) {
	if ([aView isKindOfClass:[UIButton class]]) {// calendar button
	  [aView removeFromSuperview];
	  break;
	}
  }
  
  switch(indexPath.row) {
      
    case 1: {
      cell.imageView.image = [UIImage imageNamed:@"EventsIcon"];
      cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_MYDAYS", @"Title for MyDays in the sliding menu");
	  
	  if (!self.calendarButton) {
		UIImage *calIcon = [UIImage imageNamed:@"Cal"];
		UIButton *calButton = [UIButton buttonWithType:UIButtonTypeCustom];
		calButton.frame = (CGRect){150, 27-calIcon.size.height/2, calIcon.size.width, calIcon.size.height};
		[calButton setBackgroundImage:calIcon forState:UIControlStateNormal];
	    [calButton setBackgroundImage:[UIImage imageNamed:@"CalHL"] forState:UIControlStateHighlighted];
		[calButton addTarget:self action:@selector(calButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
		[cell addSubview:calButton]; // cannot use accessory view since it will be hidden behind center view
		self.calendarButton = calButton;
	  } else {
		[cell addSubview:self.calendarButton];
	  }
	  
	  break;
	}
      
    case 2:
      cell.imageView.image = [UIImage imageNamed:@"CollectionIcon"];
      cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_COLLECTIONS", @"Title for Collections in the sliding menu");
      break;
      /*
       case 6:
       cell.imageView.image = [UIImage imageNamed:@"CalIcon"];
       cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_CALENDAR", @"Title for Calendar in the sliding menu");
       break;
       */
    case 3:
      cell.imageView.image = [UIImage imageNamed:@"SettingsIcon"];
      cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_SETTINGS", @"Title for Settings in the sliding menu");
      break;
  }
  
  return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
  
  cell.textLabel.textColor = [UIColor whiteColor];
  cell.textLabel.font = [UIFont fontWithName:NSLocalizedString(@"SLIDING_MENU_FONTNAME", @"Font name of the sliding menu") size:18.0];
  
  switch(indexPath.row) {
      
    case 1: // Events
      cell.backgroundColor = [UIColor colorWithRed:0.957 green:0.376 blue:0.298 alpha:1.0];
      break;
      
    case 2: // Collection
      cell.backgroundColor = [UIColor colorWithRed:0.039f green:0.423f blue:0.529f alpha:1.0];
      break;
      /*
       case 6: // Calendar
       cell.backgroundColor = [UIColor colorWithRed:0.949f green:0.49f blue:0.305f alpha:1.0];
       break;
       */
    case 3: // Settings
      cell.backgroundColor = [UIColor colorWithRed:0.72f green:0.701f blue:0.69f alpha:1.0];
      break;
  }
  
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  switch (indexPath.row) {
    case 1: {
      [self.viewDeckController closeLeftView];
      
      [self switchToViewStyle:WAEventsViewStyle];
      
      break;
    }
      
    case 2: {
      [self.viewDeckController closeLeftView];
      
      WACollectionViewController *collectionViewController = [[WACollectionViewController alloc] init];
      WANavigationController *navController = [[WANavigationController alloc] initWithRootViewController:collectionViewController];
      collectionViewController.view.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];
      
      collectionViewController.navigationItem.leftBarButtonItem = WABarButtonItem([UIImage imageNamed:@"menu"], @"", ^{
        [collectionViewController.viewDeckController toggleLeftView];
      });
      [self.viewDeckController setCenterController:navController];
      break;
    }
      
    case 3: { // Settings
      [self handleUserInfo];
      break;
    }
  }
  
}

#pragma mark - IIViewDeckDelegate protocol
- (BOOL)viewDeckControllerWillOpenLeftView:(IIViewDeckController *)viewDeckController animated:(BOOL)animated {
  
  if (self.navigationController && isPad()) {
    CGRect newFrame = self.navigationController.view.frame;
    newFrame.size.width = [WACalendarPickerViewController minimalCalendarWidth]; // adjust navigation bar and toolbar width to fit in sliding menu
    self.navigationController.view.frame = newFrame;
  }
  
  return YES;
  
}
- (void)viewDeckControllerDidCloseLeftView:(IIViewDeckController *)viewDeckController animated:(BOOL)animated {
  [self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - switch methods

- (void) switchToViewStyle:(WADayViewSupportedStyle)viewStyle {
  
  [self switchToViewStyle:viewStyle onDate:nil animated:NO];
  
}

- (void) switchToViewStyle:(WADayViewSupportedStyle)viewStyle onDate:(NSDate*)date {
  
  [self switchToViewStyle:viewStyle onDate:date animated:NO];
  
}

- (void) switchToViewStyle:(WADayViewSupportedStyle)viewStyle onDate:(NSDate*)date animated:(BOOL)animated {
  CGFloat animationDuration = 0.3f;
  __weak WASlidingMenuViewController *wSelf = self;
  
  UINavigationController *navVC = (UINavigationController *)[[self class] dayViewControllerForViewStyle:viewStyle];
  WADayViewController *swVC = (WADayViewController*)navVC.topViewController;
  
  if (animated) {
    
    [UIView animateWithDuration:animationDuration
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionFlipFromBottom
                     animations: ^{
                       wSelf.viewDeckController.centerController = navVC;
                     }
                     completion: ^(BOOL complete) {
                       if (date)
                         [swVC jumpToDate:date animated:NO];
                     }];
    
  } else {
    
    self.viewDeckController.centerController = navVC;
    if (date)
      [swVC jumpToDate:date animated:NO];
    
  }
  
}

- (void) calButtonTapped:(id)sender {
  
  if (isPad()) {
	
	CGRect frame = CGRectMake(0, 0, 320, 370);
	
	__weak WASlidingMenuViewController *wSelf = self;
	WACalendarPickerViewController *calVC = [[WACalendarPickerViewController alloc] initWithFrame:frame selectedDate:[NSDate date]];
	calVC.currentViewStyle = WAEventsViewStyle;
	WANavigationController *wrappedNavVC = [WACalendarPickerViewController wrappedNavigationControllerForViewController:calVC forStyle:WACalendarPickerStyleWithCancel];
	
	UIPopoverController *popOver = [[UIPopoverController alloc] initWithContentViewController:wrappedNavVC];
	popOver.popoverContentSize = frame.size;
	[popOver presentPopoverFromRect:CGRectMake(self.calendarButton.frame.size.width/2, self.calendarButton.frame.size.height, 1, 1) inView:self.calendarButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	self.calendarPopoverForIPad = popOver;
	self.calendarPopoverForIPad.delegate = self;
	calVC.onDismissBlock = ^{
	  [wSelf.calendarPopoverForIPad dismissPopoverAnimated:YES];
	  wSelf.calendarPopoverForIPad = nil;
	};
	
  } else {

	__block WACalendarPopupViewController_phone *calendarPopup = [[WACalendarPopupViewController_phone alloc] initWithCompletion:^{
	
	  [calendarPopup willMoveToParentViewController:nil];
	  [calendarPopup removeFromParentViewController];
	  [calendarPopup.view removeFromSuperview];
	  [calendarPopup didMoveToParentViewController:nil];
	  calendarPopup = nil;
	
	}];

	[self.viewDeckController addChildViewController:calendarPopup];
	[self.viewDeckController.view addSubview:calendarPopup.view];
  }
}

-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
  
  self.calendarPopoverForIPad = nil;
  
}

@end
