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

@interface WASlidingMenuViewController ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) WAUser *user;
@property (nonatomic, strong) UITableViewCell *userCell;

@property (nonatomic, strong) WAStatusBar *statusBar;

@end

@implementation WASlidingMenuViewController

+ (UIViewController *)dayViewControllerForViewStyle:(WADayViewSupportedStyle)viewStyle {
  
  NSAssert1(((viewStyle==WAEventsViewStyle) || (viewStyle == WAPhotosViewStyle) || (viewStyle == WADocumentsViewStyle) || (viewStyle == WAWebpagesViewStyle)), @"Unsupported view style: %d", viewStyle);
  
  WADayViewController *swVC = [[WADayViewController alloc] initWithStyle:viewStyle];
  WANavigationController *navVC = [[WANavigationController alloc] initWithRootViewController:swVC];
  
  if (viewStyle == WAPhotosViewStyle) {
    
    swVC.navigationController.navigationBar.tintColor = [UIColor colorWithWhite:0.157 alpha:1.000];
    swVC.navigationController.navigationBar.titleTextAttributes = @{UITextAttributeTextColor: [UIColor whiteColor]};
    [swVC.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    swVC.view.backgroundColor = [UIColor colorWithWhite:0.16f alpha:1.0f];
    
  } else {
    
    swVC.view.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];
    
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
  [self.user removeObserver:self forKeyPath:@"avatar"];
  [self.user removeObserver:self forKeyPath:@"nickname"];
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
  
  IRAction *cancelAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_CANCEL", nil) block:nil];
  IRAction *signOutAction = [IRAction
		         actionWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", nil)
		         block: ^ {
			 if ([wSelf.delegate respondsToSelector:@selector(applicationRootViewControllerDidRequestReauthentication:)])
			   [wSelf.delegate performSelector:@selector( applicationRootViewControllerDidRequestReauthentication: ) withObject:nil];
		         }];
  
  userInfoVC.navigationItem.rightBarButtonItem = [IRBarButtonItem itemWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", nil) action:^{
    
    [[IRAlertView alertViewWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", nil)
		         message:NSLocalizedString(@"SIGN_OUT_CONFIRMATION", nil)
		    cancelAction:cancelAction
		    otherActions:@[signOutAction]] show];
    
  }];
  
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
  
  [self.user addObserver:self forKeyPath:@"avatar" options:options context:nil];
  [self.user addObserver:self forKeyPath:@"nickname" options:options context:nil];
  
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
  
  if ([keyPath isEqualToString:@"isFetching"]) {
    BOOL isFetching = [change[NSKeyValueChangeNewKey] boolValue];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      if (isFetching) {
        if (!wSelf.statusBar) {
	wSelf.statusBar = [[WAStatusBar alloc] initWithFrame:CGRectZero];
        }
        wSelf.statusBar.fetchingLabel.text = NSLocalizedString(@"FETCHING_DATA", @"String on customized status bar");
      } else {
        WASyncManager *syncManager = [(WAAppDelegate_iOS *)AppDelegate() syncManager];
        if (syncManager.isSyncing) {
	wSelf.statusBar.fetchingLabel.text = @"";
        } else {
	wSelf.statusBar = nil;
        }
      }
    }];
  }
  
  if ([keyPath isEqualToString:@"isSyncing"]) {
    BOOL isSyncing = [change[NSKeyValueChangeNewKey] boolValue];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      WASyncManager *syncManager = [(WAAppDelegate_iOS *)AppDelegate() syncManager];
      if (isSyncing) {
        if (!wSelf.statusBar) {
	wSelf.statusBar = [[WAStatusBar alloc] initWithFrame:CGRectZero];
        }
        if (syncManager.isSyncFail) {
	wSelf.statusBar.syncingLabel.text = NSLocalizedString(@"PHOTO_UPLOAD_STATUS_BAR_FAIL", @"String on customized status bar");
        } else if (syncManager.needingSyncFilesCount > 0) {
	wSelf.statusBar.syncingLabel.text = [NSString stringWithFormat:NSLocalizedString(@"PHOTO_UPLOAD_STATUS_BAR_UPLOADING", @"String on customized status bar"), syncManager.syncedFilesCount, syncManager.needingSyncFilesCount];
        } else if (syncManager.needingImportFilesCount > 0) {
	wSelf.statusBar.syncingLabel.text = [NSString stringWithFormat:NSLocalizedString(@"PHOTO_UPLOAD_STATUS_BAR_IMPORTING", @"String on customized status bar"), syncManager.importedFilesCount, syncManager.needingImportFilesCount];
        }
      } else {
        WAFetchManager *fetchManager = [(WAAppDelegate_iOS *)AppDelegate() fetchManager];
        if (fetchManager.isFetching) {
	wSelf.statusBar.syncingLabel.text = @"";
        } else {
	wSelf.statusBar = nil;
        }
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
  return 8;
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
    
    
    if ([[self.user observationInfo] count] == 0) {
      [self registerObserver];
    }
    
    return _userCell;
    
  }
  
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
  }
  
  switch(indexPath.row) {
      
    case 1:
      cell.imageView.image = [UIImage imageNamed:@"EventsIcon"];
      cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_EVENTS", @"Title for Events in the sliding menu");
      break;
      
    case 2:
      cell.imageView.image = [UIImage imageNamed:@"PhotosIcon"];
      cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_PHOTOS", @"Title for Photos in the sliding menu");
      break;
      
    case 3:
      cell.imageView.image = [UIImage imageNamed:@"DocumentsIcon"];
      cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_DOCS", @"Title for Documents in the sliding menu");
      break;
      
    case 4:
      cell.imageView.image = [UIImage imageNamed:@"Webicon"];
      cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_WEBS", @"Title for Web pages in the sliding menu");
      break;
      
    case 5:
      cell.imageView.image = [UIImage imageNamed:@"CollectionIcon"];
      cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_COLLECTIONS", @"Title for Collections in the sliding menu");
      break;
      
    case 6:
      cell.imageView.image = [UIImage imageNamed:@"CalIcon"];
      cell.textLabel.text = NSLocalizedString(@"SLIDING_MENU_TITLE_CALENDAR", @"Title for Calendar in the sliding menu");
      break;
      
    case 7:
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
      
    case 2: // Photos
      cell.backgroundColor = [UIColor colorWithRed:0.96f green:0.647f blue:0.011f alpha:1.0];
      break;
      
    case 3: // Documents
      cell.backgroundColor = [UIColor colorWithRed:0.572f green:0.8f blue:0.647f alpha:1.0f];
      break;
      
    case 4: // Web Pages
      cell.backgroundColor = [UIColor colorWithRed:0.211f green:0.694f blue:0.749f alpha:1.0f];
      break;
      
    case 5: // Collection
      cell.backgroundColor = [UIColor colorWithRed:0.039f green:0.423f blue:0.529f alpha:1.0];
      break;
      
    case 6: // Calendar
      cell.backgroundColor = [UIColor colorWithRed:0.949f green:0.49f blue:0.305f alpha:1.0];
      break;
      
    case 7: // Settings
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
      
      [self switchToViewStyle:WAPhotosViewStyle];
      
      break;
    }
    case 3: {
      [self.viewDeckController closeLeftView];
      [self switchToViewStyle:WADocumentsViewStyle];
      break;
    }
      
    case 4: {
      [self.viewDeckController closeLeftView];
      [self switchToViewStyle:WAWebpagesViewStyle];
      break;
    }
      
    case 5: {
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
      
    case 6: {
      [self.viewDeckController closeLeftView];
      
      WACalendarPickerViewController *dpVC = [[WACalendarPickerViewController alloc] initWithFrame:self.view.frame style:WACalendarPickerStyleMenuToday selectedDate:[NSDate date]];
      [dpVC setModalPresentationStyle:UIModalPresentationFullScreen];
      [self.viewDeckController setCenterController:dpVC];
      break;
    }
      
    case 7: { // Settings
      [self handleUserInfo];
      break;
    }
  }
  
}

#pragma mark - IIViewDeckDelegate protocol

- (void)viewDeckController:(IIViewDeckController *)viewDeckController applyShadow:(CALayer *)shadowLayer withBounds:(CGRect)rect {
  // No shadow
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

@end
