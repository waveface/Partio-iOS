//
//  WAContactPickerViewController.m
//  wammer
//
//  Created by Greener Chen on 13/4/2.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAContactPickerViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "WAContactPickerSectionHeaderView.h"
#import <BlocksKit/BlocksKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface WAContactPickerViewController () <UITableViewDelegate, UITableViewDataSource, FBFriendPickerDelegate, UITextFieldDelegate>
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
  
  [self setTitle:NSLocalizedString(@"TITLE_INVITE_CONTACTS", @"TITLE_INVITE_CONTACTS")];

  __weak WAContactPickerViewController *wSelf = self;
  self.navigationItem.leftBarButtonItem = WAPartioBackButton(^{
    [wSelf.navigationController popViewControllerAnimated:YES];
  });
  self.navigationItem.title = @"Invite Friends";
  
  [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
  
  [self.navigationController setToolbarHidden:NO];
  [self.navigationController.toolbar setBarStyle:UIBarStyleBlackTranslucent];
  UIBarButtonItem *flexspace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [self setToolbarItems:@[flexspace, [self shareBarButton], flexspace] animated:YES];
}

- (UIBarButtonItem *)shareBarButton
{
  static UIButton *aButton;
  aButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [aButton setFrame:CGRectMake(0.f, 0.f, 100.f, 40.f)];
  [aButton setTitle:@"Share" forState:UIControlStateNormal];
  [aButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [aButton.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:24.f]];
  [aButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
  [aButton setBackgroundImage:[UIImage imageNamed:@"Btn"] forState:UIControlStateNormal];
  [aButton setBackgroundImage:[UIImage imageNamed:@"Btn1"] forState:UIControlStateHighlighted];
  [aButton addTarget:self action:@selector(done) forControlEvents:UIControlEventTouchUpInside];
  
  return [[UIBarButtonItem alloc] initWithCustomView:aButton];
}

- (void)done
{
  if (self.onNextHandler) {
    self.onNextHandler([NSArray arrayWithArray:_members]);
  }
  
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 22.f)];
  headerView.backgroundColor = tableView.backgroundColor;
  
  UILabel *titleLabel = [[UILabel alloc] initWithFrame:headerView.frame];
  [titleLabel setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:14.f]];
  [titleLabel setTextColor:[UIColor whiteColor]];
  [titleLabel setText:NSLocalizedString(@"MEMBERS_LABEL_CONTACT_PICKER", @"MEMBERS_LABEL_CONTACT_PICKER")];
  [titleLabel setTextAlignment:NSTextAlignmentCenter];
  [titleLabel setBackgroundColor:[UIColor clearColor]];
  [headerView addSubview:titleLabel];
  
  [headerView.layer setMasksToBounds:NO];
  [headerView.layer setShadowPath:[[UIBezierPath bezierPathWithRect:CGRectMake(0.f, -2.5f, 320.f, 27.f)] CGPath]];
  [headerView.layer setDoubleSided:YES];
  [headerView.layer setShadowOffset:CGSizeMake(0.f, 2.5f)];
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
  
  [cell.textLabel setTextColor:[UIColor whiteColor]];
  [cell.detailTextLabel setFont:[UIFont fontWithName:@"OpenSans-Regular" size:14.f]];
  [cell.detailTextLabel setTextColor:[UIColor colorWithRed:0.537 green:0.537 blue:0.537 alpha:1.0]];
  
  if (indexPath.section == 0) {
    [cell.textLabel setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:18.f]];
    
    if (indexPath.row == 0) {
      [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
      
      for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
      }
      
      UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(5.f, 5.f, 310.f, 34.f)];
      [textField setBorderStyle:UITextBorderStyleRoundedRect];
      [textField setPlaceholder:NSLocalizedString(@"INPUT_RECEIVER_EMAIL", @"INPUT_RECEIVER_EMAIL")];
      [textField setClearButtonMode:UITextFieldViewModeWhileEditing];
      
      // Manage keyboard for email input
      [textField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
      [textField setAutocorrectionType:UITextAutocorrectionTypeNo];
      [textField setSpellCheckingType:UITextSpellCheckingTypeNo];
      [textField setEnablesReturnKeyAutomatically:YES];
      [textField setKeyboardAppearance:UIKeyboardAppearanceDefault];
      [textField setKeyboardType:UIKeyboardTypeEmailAddress];
      [textField setReturnKeyType:UIReturnKeyDone];
      [textField setSecureTextEntry:NO];
      textField.delegate = self;
      
      [cell.contentView addSubview:textField];
      
      
    } else if (indexPath.row == 1) {
      cell.imageView.image = [UIImage imageNamed:@"FacebookLogo"];
      cell.textLabel.text = @"Contacts";
      cell.detailTextLabel.text = @"Find friends from your contacts.";
      
    } else if (indexPath.row == 2) {
      cell.imageView.image = [UIImage imageNamed:@"FacebookLogo"];
      cell.textLabel.text = @"Facebook";
      cell.detailTextLabel.text = @"Find friends from Facebook.";
      
    }
    
  } else {
    [cell.textLabel setFont:[UIFont fontWithName:@"OpenSans-Regular" size:18.f]];
    
    cell.imageView.image = [UIImage imageNamed:@"Avatar"];

    NSString *name = _members[indexPath.row][@"name"];
    if (name) {
      cell.textLabel.text = name;
    }
    
    NSArray *emails = _members[indexPath.row][@"email"];
    if ([emails count]) {
      cell.detailTextLabel.text = emails[0];
    }
    
  }
  
  return cell;
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
  NSLog(@"Email input: %@", textField.text);
  [self addEmailIntoInvitedList:textField.text];
  [self.tableView reloadData];
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
