//
//  WAContactPickerViewController.m
//  wammer
//
//  Created by Greener Chen on 13/4/2.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAContactPickerViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "WAAppearance.h"
#import "WATranslucentToolbar.h"
#import "WAPartioNavigationBar.h"

#import "WAContactPickerSectionHeaderView.h"
#import <BlocksKit/BlocksKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface WAContactPickerViewController () <UITableViewDelegate, UITableViewDataSource, FBFriendPickerDelegate, UITextFieldDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet WAPartioNavigationBar *navigationBar;
@property (nonatomic, strong) FBFriendPickerViewController *fbFriendPickerViewController;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UITapGestureRecognizer *tap;

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
  
  __weak WAContactPickerViewController *wSelf = self;
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
  self.navigationItem.title = NSLocalizedString(@"TITLE_INVITE_CONTACTS", @"TITLE_INVITE_CONTACTS");
  
  [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];

  [self.toolbar setBackgroundImage:[[UIImage alloc] init] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
  self.toolbar.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.4f];
  UIBarButtonItem *flexspace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
//  self.toolbar = [[WATranslucentToolbar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame)-44, CGRectGetWidth(self.view.frame), 44)];
  
  self.toolbar.items = @[flexspace, [self shareBarButton], flexspace];
  [self.view addSubview:self.toolbar];
  
  self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
  [self.tap setCancelsTouchesInView:NO];
  [self.view addGestureRecognizer:self.tap];
}

- (UIBarButtonItem *)shareBarButton
{ 
  return WAPartioToolbarNextButton(@"Share", ^{
    if (self.onNextHandler) {
      self.onNextHandler([NSArray arrayWithArray:_members]);
    }
  });
}

- (void)dismissKeyboard
{
  if ([self.textField isEditing]) {
    [self.textField setText:@""];
    [self.textField resignFirstResponder];
    [self.tap setCancelsTouchesInView:NO];
  }
  
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (BOOL) shouldAutorotate {
  return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
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
    return 2;
    
  } else {
    return [_members count];
  
  }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  WAContactPickerSectionHeaderView *headerView = [[WAContactPickerSectionHeaderView alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 22.f)];
  headerView.backgroundColor = tableView.backgroundColor;
  [headerView.title setText: NSLocalizedString(@"MEMBERS_LABEL_CONTACT_PICKER", @"MEMBERS_LABEL_CONTACT_PICKER")];
  [headerView.title setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:14.f]];
  [headerView.title setTextColor:[UIColor whiteColor]];
  [headerView.title setTextAlignment:NSTextAlignmentCenter];
  
  [headerView.layer setMasksToBounds:NO];
  [headerView.layer setShadowPath:[[UIBezierPath bezierPathWithRect:CGRectMake(0.f, 0.f, 320.f, 22.f)] CGPath]];
  [headerView.layer setDoubleSided:YES];
  [headerView.layer setShadowRadius:2.f];
  [headerView.layer setShadowOffset:CGSizeMake(0.f, 2.f)];
  [headerView.layer setShadowColor:[[UIColor blackColor] CGColor]];
  [headerView.layer setShadowOpacity:0.5f];

  return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  if (!section) {
    return 0.f;
  
  } else {
    return 22.f;
  
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
  }
  cell.selectionStyle = UITableViewCellSelectionStyleGray;
  
  [cell.textLabel setTextColor:[UIColor whiteColor]];
  [cell.detailTextLabel setFont:[UIFont fontWithName:@"OpenSans-Regular" size:14.f]];
  [cell.detailTextLabel setTextColor:[UIColor colorWithRed:0.537 green:0.537 blue:0.537 alpha:1.0]];
  
  if (indexPath.section == 0) {
    [cell.textLabel setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:20.f]];
    
    if (indexPath.row == 0) {
      [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
      
      for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
      }
      
      self.textField = [[UITextField alloc] initWithFrame:CGRectMake(5.f, 5.f, 310.f, 34.f)];
      [self.textField setBorderStyle:UITextBorderStyleRoundedRect];
      [self.textField setPlaceholder:NSLocalizedString(@"INPUT_RECEIVER_EMAIL", @"INPUT_RECEIVER_EMAIL")];
      [self.textField setClearButtonMode:UITextFieldViewModeWhileEditing];
      [self.textField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
      
      // Manage keyboard for email input
      [self.textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
      [self.textField setAutocorrectionType:UITextAutocorrectionTypeNo];
      [self.textField setSpellCheckingType:UITextSpellCheckingTypeNo];
      [self.textField setEnablesReturnKeyAutomatically:YES];
      [self.textField setKeyboardAppearance:UIKeyboardAppearanceDefault];
      [self.textField setKeyboardType:UIKeyboardTypeEmailAddress];
      [self.textField setReturnKeyType:UIReturnKeyDone];
      [self.textField setSecureTextEntry:NO];
      self.textField.delegate = self;
      
      [cell.contentView addSubview:self.textField];
      
      
    } else if (indexPath.row == 1) {
      cell.imageView.image = [UIImage imageNamed:@"contact"];
      cell.textLabel.text = @"Contacts";
      cell.detailTextLabel.text = @"Find friends from your contacts.";
      
    } else if (indexPath.row == 2) {
      cell.imageView.image = [UIImage imageNamed:@"FB"];
      cell.textLabel.text = @"Facebook";
      cell.detailTextLabel.text = @"Find friends from Facebook.";
      
    }
    
  } else {
    [cell.textLabel setFont:[UIFont fontWithName:@"OpenSans-Regular" size:20.f]];
    
    cell.imageView.image = [UIImage imageNamed:@"Avatar"];

    NSString *name = _members[indexPath.row][@"name"];
    if (name) {
      cell.textLabel.text = name;
    }
    
    NSArray *emails = _members[indexPath.row][@"email"];
    if ([emails count]) {
      cell.detailTextLabel.text = emails[0];
    }
    
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    cell.accessoryView = [self checkmark];
    
  }
  
  return cell;
}

- (UIImageView *)checkmark
{
  return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checked"]];
}

- (UIButton *)invitedButton
{
  UIButton *aButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [aButton setFrame:CGRectMake(0.f, 0.f, 75.f, 30.f)];
  [aButton setBackgroundColor:[UIColor colorWithRed:0.894 green:0.435 blue:0.353 alpha:1.0]];
  [aButton setTitle:NSLocalizedString(@"LABEL_INVITED_BUTTON", @"LABEL_INVITED_BUTTON") forState:UIControlStateNormal];
  [aButton.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Regular" size:18.f]];
  [aButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [aButton.layer setCornerRadius:15.f];
  [aButton setClipsToBounds:YES];
  [aButton setEnabled:NO];
  
  return aButton;
}

- (UIButton *)nudgeButton
{
  UIButton *aButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [aButton setFrame:CGRectMake(0.f, 0.f, 75.f, 30.f)];
  [aButton setBackgroundColor:[UIColor colorWithRed:0.984 green:0.804 blue:0.02 alpha:1.0]];
  [aButton setTitle:NSLocalizedString(@"LABEL_NUDGE_BUTTON", @"LABEL_NUDGE_BUTTON") forState:UIControlStateNormal];
  [aButton.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Regular" size:18.f]];
  [aButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [aButton.layer setCornerRadius:15.f];
  [aButton setClipsToBounds:YES];
  
  return aButton;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
  NSLog(@"Email input: %@", textField.text);
  if (![textField.text isEqualToString:@""]) {
    [self addEmailIntoInvitedList:textField.text];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_members.count-1 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  //validate content
  if ([self NSStringIsValidEmail:textField.text]) {
    NSLog(@"Valid email:%@", textField.text);
    [textField resignFirstResponder];
    return YES;
    
  } else {
    NSLog(@"Invalid email:%@", textField.text);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"TITLE_ERROR_INVALID_EMAIL_FORMAT", @"TITLE_ERROR_INVALID_EMAIL_FORMAT") message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"ACTION_OKAY", @"ACTION_OKAY") otherButtonTitles:nil];
    [alert show];
    
    return NO;
  }

}

- (void)addEmailIntoInvitedList:(NSString *)email
{
  NSString *name = email;
  NSDictionary *aPerson = @{@"name": name, @"email": @[email]};
  
  if (![_members containsObject:aPerson]) {
    [_members addObject:aPerson];
  }
}

- (BOOL)NSStringIsValidEmail:(NSString *)checkString
{
  BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
  NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
  NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
  NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
  NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
  
  return [emailTest evaluateWithObject:checkString];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  if (indexPath.section == 0) {
    if (!indexPath.row) {
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
      
      [self.tap setCancelsTouchesInView:YES];
      [alert show];
      
    } else if (indexPath.row == 1) {
      ABPeoplePickerNavigationController *abPicker = [[ABPeoplePickerNavigationController alloc] init];
      abPicker.peoplePickerDelegate = self;
      
      [self presentViewController:abPicker animated:YES completion:nil];
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
    if (!name) {
      name = allEmail[0];
      
    }
  } else {
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"TITLE_INPUT_EMAIL_ALERT", @"TITLE_INPUT_EMAIL_ALERT"), name];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:NSLocalizedString(@"MESSAGE_EMAIL_REQUEST", @"MESSAGE_EMAIL_REQUEST")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"ACTION_CANCEL", @"ACTION_CANCEL")
                                          otherButtonTitles:NSLocalizedString(@"ACTION_INVITE", @"ACTION_INVITE"), nil];
    
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    
    // Manage keyboard for email input
    UITextField *textField = [alert textFieldAtIndex:0];
    [textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [textField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [textField setSpellCheckingType:UITextSpellCheckingTypeNo];
    [textField setEnablesReturnKeyAutomatically:YES];
    [textField setKeyboardAppearance:UIKeyboardAppearanceDefault];
    [textField setKeyboardType:UIKeyboardTypeEmailAddress];
    [textField setReturnKeyType:UIReturnKeyDone];
    [textField setSecureTextEntry:NO];
    
    [alert show];
  }
  
  NSString *phone = @"";
  ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
  if (ABMultiValueGetCount(phoneNumbers) > 0) {
    phone = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
    
  }
  CFRelease(phoneNumbers);
  
  if ([email count]) {
    NSDictionary *aPerson = @{@"name": name,
                              @"email": email,
                              @"phone": phone};

    if (![_members containsObject:aPerson]) {
      [_members addObject:aPerson];
    }
  }
  
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == 1) {
    NSArray *words = [[alertView title] componentsSeparatedByString:@" "];
    NSString *name;
    if ([words count] == 3) {
      name = words[1];
      
    } else if ([words count] == 4) {
      name = [NSString stringWithFormat:@"%@ %@", words[1], words[2]];
      
    }
    
    NSString *email = [[alertView textFieldAtIndex:0] text];
    if (![self NSStringIsValidEmail:email]) {
      return;
    }
    
    if (!name) {
      name = email;
    }
    NSDictionary *aPerson = @{@"name": name, @"email": @[email]};
    
    if (![_members containsObject:aPerson]) {
      [_members addObject:aPerson];
    }
    
    [self.tableView reloadData];
  }
}

@end
