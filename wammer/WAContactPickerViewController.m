//
//  WAContactPickerViewController.m
//  wammer
//
//  Created by Greener Chen on 13/4/2.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAContactPickerViewController.h"
#import "WAContactPickerSectionHeaderView.h"
#import <BlocksKit/BlocksKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface WAContactPickerViewController () <UITableViewDelegate, UITableViewDataSource, FBFriendPickerDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, strong) FBFriendPickerViewController *fbFriendPickerViewController;
@end

@implementation WAContactPickerViewController

- (id) init {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    // Custom initialization
    _members = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
  
  __weak WAContactPickerViewController *wSelf = self;
  self.navigationItem.leftBarButtonItem = WAPartioBackButton(^{
    [wSelf.navigationController popViewControllerAnimated:YES];
  });
  self.navigationItem.title = @"Invite Friends";
  
  [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
}

- (void)done
{
  if (self.onNextHandler) {
    self.onNextHandler([NSArray arrayWithArray:_members]);
  }
  
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  // Return the number of sections.
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  // Return the number of rows in the section.
  if (section == 0) {
    return 3;
    
  } else {
    return [_members count];
  
  }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  WAContactPickerSectionHeaderView *header = [[[UINib nibWithNibName:@"WAContactPickerSectionHeaderView" bundle:[NSBundle mainBundle]] instantiateWithOwner:nil options:nil] lastObject];
  
  if (section == 0) {
    header.title.text = @"Select contacts";
  } else {
    header.title.text = @"Selected contacts";
  }
  return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
  }
  
  [cell.textLabel setTextColor:[UIColor whiteColor]];
  
  // Configure the cell...
  if (indexPath.section == 0) {
    if (indexPath.row == 0) {
      cell.textLabel.text = NSLocalizedString(@"INPUT_RECEIVER_EMAIL", @"INPUT_RECEIVER_EMAIL");
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      
    } else if (indexPath.row == 1) {
      cell.imageView.image = [UIImage imageNamed:@"FacebookLogo"];
      cell.textLabel.text = @"Contacts";
      cell.detailTextLabel.text = @"Find friends from your contacts.";
      [cell.detailTextLabel setTextColor:[UIColor lightGrayColor]];
      
    } else if (indexPath.row == 2) {
      cell.imageView.image = [UIImage imageNamed:@"FacebookLogo"];
      cell.textLabel.text = @"Facebook";
      [cell.textLabel setTextColor:[UIColor whiteColor]];
      cell.detailTextLabel.text = @"Find friends from Facebook.";
      [cell.detailTextLabel setTextColor:[UIColor lightGrayColor]];
      
    }
    
  } else {
    cell.imageView.image = [UIImage imageNamed:@"FacebookLogo"];

    NSString *name = _members[indexPath.row][@"name"];
    if (name) {
      cell.textLabel.text = name;
    }
    
    NSArray *emails = _members[indexPath.row][@"email"];
    if ([emails count]) {
      cell.detailTextLabel.text = emails[0];
    }
    
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
  }
  
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  if (indexPath.section == 0) {
    if (indexPath.row == 0) {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"TITLE_INPUT_EMAIL", @"Title of dialog to input email") message:NSLocalizedString(@"MESSAGE_INPUT_EMAIL", @"Message of dialog to input email")];
      __weak UIAlertView *wAlert = alert;
      alert.alertViewStyle = UIAlertViewStylePlainTextInput;
      [alert setCancelButtonWithTitle:NSLocalizedString(@"ACTION_CANCEL", @"Cancel adding selected photos into collection") handler:nil];
      [alert addButtonWithTitle:NSLocalizedString(@"ACTION_INPUT_EMAIL", @"The action to create a new collection") handler:^{
        NSString *email = [wAlert textFieldAtIndex:0].text;
        NSDictionary *contact = @{@"name": email, @"email": @[email]};
        if (![_members containsObject:contact])
          [_members addObject:contact];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_members.count-1 inSection:1];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
      }];
      
      [alert show];

    } else if (indexPath.row == 1) {
      ABPeoplePickerNavigationController *abPicker = [[ABPeoplePickerNavigationController alloc] init];
      abPicker.peoplePickerDelegate = self;
    
      [self presentViewController:abPicker animated:YES completion:nil];
    } else if (indexPath.row == 2) {
//      self.fbFriendPickerViewController = [[FBFriendPickerViewController alloc] initWithNibName:nil bundle:nil];
//      self.fbFriendPickerViewController.title = NSLocalizedString(@"FB_FRIEND_PICKER_TITLE", @"Title of FB friends picker");
//      self.fbFriendPickerViewController.delegate = self;
//      [self.fbFriendPickerViewController loadData];
//      [self.navigationController presentViewController:self.fbFriendPickerViewController animated:YES completion:nil];
    }
  }
}

#pragma - Address Book Contacts Picker

- (void)showContactsPicker:(id)sender
{
  ABPeoplePickerNavigationController *abPicker = [[ABPeoplePickerNavigationController alloc] init];
  abPicker.peoplePickerDelegate = self;
  
  [self presentViewController:abPicker animated:YES completion:nil];
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
  [self addIntoInvitedList:person];
  [self dismissViewControllerAnimated:YES completion:nil];
  [self.tableView reloadData];
  
  return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
  return NO;
}

- (void)addIntoInvitedList:(ABRecordRef)person
{
  NSString *firstname = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
  NSString *lastname = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
  NSString *name = @"";
  
  if (firstname && lastname) {
    if (ABPersonGetCompositeNameFormat() == kABPersonCompositeNameFormatFirstNameFirst) {
      name = [NSString stringWithFormat:@"%@ %@", firstname, lastname];
    
    } else {
      name = [NSString stringWithFormat:@"%@ %@", lastname, firstname];
      
    }
  
  } else if (firstname && !lastname) {
    name = firstname;
  
  } else if (!firstname && lastname) {
    name = lastname;
    
  }
  
  NSArray *email = @[];
  NSArray *allEmail = (__bridge_transfer NSArray*)ABMultiValueCopyArrayOfAllValues(ABRecordCopyValue(person, kABPersonEmailProperty));
  if ([allEmail count]) {
    email = allEmail;
    
  } else {
    //TODO: prompt dialog to input email
  }
  
  NSString *phone = @"";
  ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
  if (ABMultiValueGetCount(phoneNumbers) > 0) {
    phone = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
    
  }
  CFRelease(phoneNumbers);
  
  NSDictionary *aPerson = @{@"name": name,
                            @"email": email,
                            @"phone": phone};

  if (![_members containsObject:aPerson]) {
    [_members addObject:aPerson];
  }
  
}

@end
