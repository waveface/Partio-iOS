//
//  WAFBFriendPickerViewController.m
//  wammer
//
//  Created by Greener Chen on 13/5/13.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAFBFriendPickerViewController.h"
#import "WAPartioNavigationBar.h"
#import "WAPartioTableViewSectionHeaderView.h"
#import <SMCalloutView/SMCalloutView.h>
#import <BlocksKit/BlocksKit.h>

@interface WAFBFriendPickerViewController () <FBFriendPickerDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet WAPartioNavigationBar *navigationBar;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) NSMutableArray *contacts;
@property (nonatomic, strong) NSArray *dataDisplay;
@property (nonatomic, strong) NSMutableArray *filteredContacts;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) SMCalloutView *inviteInstructionView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end

static NSString *kPlaceholderChooseFriends;
static NSString *kWAFBFriendPickerViewController_CoachMarks = @"kWAFBFriendPickerViewController_CoachMarks";

@implementation WAFBFriendPickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
    self.delegate = self;
    
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  BOOL coachmarkShown = [[NSUserDefaults standardUserDefaults] boolForKey:kWAFBFriendPickerViewController_CoachMarks];
  if (!coachmarkShown) {
    __weak WAFBFriendPickerViewController *wSelf = self;
    if (!self.inviteInstructionView) {
      self.inviteInstructionView = [SMCalloutView new];
      self.inviteInstructionView.title = NSLocalizedString(@"INSTRUCTION_IN_ADDRESS_BOOK_PICKER", @"The instruction show to tap contacts then share photos");
      [self.inviteInstructionView presentCalloutFromRect:CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height-44, 1, 1) inView:self.view constrainedToView:self.view permittedArrowDirections:SMCalloutArrowDirectionDown animated:YES];
      self.tapGesture = [[UITapGestureRecognizer alloc] initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        if (wSelf.inviteInstructionView) {
          [wSelf.inviteInstructionView dismissCalloutAnimated:YES];
          wSelf.inviteInstructionView = nil;
        }
        [wSelf.view removeGestureRecognizer:wSelf.tapGesture];
        wSelf.tapGesture = nil;
      }];
      [self.view addGestureRecognizer:self.tapGesture];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWAFBFriendPickerViewController_CoachMarks];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
  
  [self.tableView setBackgroundColor:[UIColor colorWithRed:0.168 green:0.168 blue:0.168 alpha:1]];
  kPlaceholderChooseFriends = NSLocalizedString(@"PLACEHOLER_FB_FRIENDS_PICKER", @"PLACEHOLER_FB_FRIENDS_PICKER");
  [self.textView setText:kPlaceholderChooseFriends];
  [self.textView setFont:[UIFont fontWithName:@"OpenSans-Regular" size:18.f]];
  
  __weak WAFBFriendPickerViewController *wSelf = self;
  if (self.navigationController) {
    self.navigationItem.leftBarButtonItem = WAPartioBackButton(^{
      [wSelf.navigationController popViewControllerAnimated:YES];
      if (self.onDismissHandler)
        self.onDismissHandler();
    });
  } else {
    self.navigationItem.leftBarButtonItem = (UIBarButtonItem*)WABarButtonItem(nil, NSLocalizedString(@"ACTION_CANCEL", @"cancel"), ^{
      if (wSelf.onDismissHandler)
        wSelf.onDismissHandler();
    });
  }
  
  
  [self.navigationItem setTitle:NSLocalizedString(@"TITLE_INVITE_CONTACTS", @"TITLE_INVITE_CONTACTS")];
  [self.navigationController setNavigationBarHidden:YES];
  [self.navigationItem setHidesBackButton:YES];
  [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
  
  [self.toolbar setBackgroundImage:[[UIImage alloc] init] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
  self.toolbar.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.4f];
  UIBarButtonItem *flexspace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  self.toolbar.items = @[flexspace, [self shareBarButton], flexspace];
  [[self.toolbar.items objectAtIndex:1] setEnabled:NO];
  [self.view addSubview:self.toolbar];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textViewDidChange:)
                                               name:UITextViewTextDidChangeNotification
                                             object:self.textView];
  
  self.allowsMultipleSelection = YES;
  self.itemPicturesEnabled = YES;
    
  FBCacheDescriptor *cacheDescriptor = [WAFBFriendPickerViewController cacheDescriptor];
  [cacheDescriptor prefetchAndCacheForSession:FBSession.activeSession];
  
}

- (void)viewDidAppear:(BOOL)animated
{
  // add joined members into member list
  self.members = [[NSMutableArray alloc] init];
  self.filteredContacts = [[NSMutableArray alloc] init];
  
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void) dealloc {
  if (self.tapGesture)
    [self.view removeGestureRecognizer:self.tapGesture];
}

- (BOOL) shouldAutorotate {
  return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

- (UIBarButtonItem *)shareBarButton
{
  return WAPartioToolbarNextButton(@"Share", ^{
    if (self.onNextHandler) {
      self.onNextHandler([NSArray arrayWithArray:self.members]);
    }
  });
}

- (void)resetTextViewPlaceholder
{
  [self.textView setText:kPlaceholderChooseFriends];
}

- (void)updateNavigationBarTitle
{
  if (![self.members count]) {
    [[self.toolbar.items objectAtIndex:1] setEnabled:NO];
    self.navigationItem.title = NSLocalizedString(@"TITLE_INVITE_CONTACTS", @"TITLE_INVITE_CONTACTS");
  } else {
    self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"TITLE_INVITATION_NUMBERS", @"TITLE_INVITATION_NUMBERS"), [self.members count]];
  }
}

#pragma mark - FBFriendPickerDelegate

- (void)friendPickerViewController:(FBFriendPickerViewController *)friendPicker handleError:(NSError *)error
{
  NSLog(@"Error during FB friend data fetch.");
}

- (BOOL)friendPickerViewController:(FBFriendPickerViewController *)friendPicker shouldIncludeUser:(id<FBGraphUser>)user
{
  // friend filter result
  // Filtering example: only show users who have
  // "ch" in their names
  NSRange result = [user.name rangeOfString:@"ch"
                                    options:NSCaseInsensitiveSearch];
  if (result.location != NSNotFound) {
    return YES;
  } else {
    return NO;
  }
}

- (void)friendPickerViewControllerDataDidChange:(FBFriendPickerViewController *)friendPicker
{
  NSLog(@"FB friend data loaded.");
}

- (void)friendPickerViewControllerSelectionDidChange:(FBFriendPickerViewController *)friendPicker
{
  NSLog(@"Current friend selections: %@", friendPicker.selection);
}

#pragma mark - UITableViewDataSource

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  WAPartioTableViewSectionHeaderView *headerView = [[WAPartioTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0.f, 2.f, 320.f, 22.f)];
  headerView.backgroundColor = tableView.backgroundColor;
  //headerView.title.text = NSLocalizedString(@"LABEL_CONTACTS_FRIENDS", @"LABEL_CONTACTS_FRIENDS");
    
  return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  return 22.f;
}

@end
