//
//  WAContactPickerViewController.m
//  wammer
//
//  Created by Greener Chen on 13/4/2.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAContactPickerViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface WAContactPickerViewController () <UITextFieldDelegate, UITextInputTraits>

@end

@implementation WAContactPickerViewController

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
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
  self.navigationItem.rightBarButtonItem = [self shareBarButton];
  
}

- (UIBarButtonItem *)shareBarButton
{
  static UIButton *aButton;
  aButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [aButton setFrame:CGRectMake(0.f, 0.f, 58.f, 31.f)];
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
    self.onNextHandler(_members);
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 22.f)];
  headerView.backgroundColor = tableView.backgroundColor;
  
  UILabel *titleLabel = [[UILabel alloc] initWithFrame:headerView.frame];
  [titleLabel setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:24.f]];
  [titleLabel setTextColor:[UIColor whiteColor]];
  [titleLabel setText:NSLocalizedString(@"MEMBERS_LABEL_CONTACT_PICKER", @"MEMBERS_LABEL_CONTACT_PICKER")];
  [titleLabel setTextAlignment:NSTextAlignmentCenter];
  [titleLabel setBackgroundColor:[UIColor clearColor]];
  [headerView addSubview:titleLabel];
  
  [headerView.layer setMasksToBounds:NO];
  [headerView.layer setShadowPath:[[UIBezierPath bezierPathWithRect:CGRectMake(0.f, -5.f, 320.f, 32.f)] CGPath]];
  [headerView.layer setDoubleSided:YES];
  [headerView.layer setShadowOffset:CGSizeMake(0.f, 5.f)];
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
  [cell.detailTextLabel setFont:[UIFont fontWithName:@"OpenSans-Regular" size:24.f]];
  [cell.detailTextLabel setTextColor:[UIColor colorWithRed:0.537 green:0.537 blue:0.537 alpha:1.0]];
  
  if (indexPath.section == 0) {
    [cell.textLabel setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:30.f]];
    
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
      
      [cell.contentView addSubview:textField];
      
//      UIBarButtonItem *textFieldDoneBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStyleDone target:self action:@selector(nil)];
      
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
    [cell.textLabel setFont:[UIFont fontWithName:@"OpenSans-Regular" size:30.f]];
    
    cell.imageView.image = [UIImage imageNamed:@"Avatar"];

    NSString *name = _members[indexPath.row][@"name"];
    if (name) {
      cell.textLabel.text = name;
    }
    
    NSArray *emails = _members[indexPath.row][@"email"];
    if ([emails count]) {
      cell.detailTextLabel.text = emails[0];
    }
    
    cell.accessoryView = [self sharedCheckedButton];
    
    switch (indexPath.row) {
      case 0:
        break;
        
      case 1:
        [cell.accessoryView addSubview:[self sharedInvitedButton]];
        break;
        
      case 2:
        [cell.accessoryView addSubview:[self sharedNudgeButton]];
        break;
    }
  
  }
  
  return cell;
}

- (UIButton *)sharedCheckedButton
{
  static UIButton *aButton;
  aButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [aButton setImage:[UIImage imageNamed:@"Checked"] forState:UIControlStateNormal];
  [aButton addTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
  
  return aButton;
}

- (UIButton *)sharedInvitedButton
{
  static UIButton *aButton;
  aButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [aButton setFrame:CGRectMake(0.f, 0.f, 75.f, 27.f)];
  [aButton setTitle:@"Invited" forState:UIControlStateNormal];
  [aButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [aButton.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Regular" size:30.f]];
  [aButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
  [aButton setBackgroundColor:[UIColor colorWithRed:0.894 green:0.435 blue:0.353 alpha:1.0]];
  [aButton.layer setCornerRadius:30.f];
  [aButton setClipsToBounds:YES];
  [aButton addTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
  
  return aButton;

}

- (UIButton *)sharedNudgeButton
{
  static UIButton *aButton;
  aButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [aButton setFrame:CGRectMake(0.f, 0.f, 75.f, 27.f)];
  [aButton setTitle:@"Nudge" forState:UIControlStateNormal];
  [aButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [aButton.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Regular" size:30.f]];
  [aButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
  [aButton setBackgroundColor:[UIColor colorWithRed:0.984 green:0.804 blue:0.02 alpha:1.0]];
  [aButton.layer setCornerRadius:30.f];
  [aButton setClipsToBounds:YES];
  [aButton addTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
  
  return aButton;

}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{}

- (void)textFieldDidEndEditing:(UITextField *)textField
{}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
  //validate content
  if ([self NSStringIsValidEmail:textField.text]) {
    return YES;
  } else {
    return NO;
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
