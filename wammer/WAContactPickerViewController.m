//
//  WAContactPickerViewController.m
//  wammer
//
//  Created by Greener Chen on 13/4/2.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAContactPickerViewController.h"

@interface WAContactPickerViewController ()

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
  
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
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
  UIView *headerView = [super tableView:tableView viewForHeaderInSection:section];
  // Customize the header view
  
  return headerView;
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
    
    NSString *email = _members[indexPath.row][@"email"];
    if (email) {
      cell.detailTextLabel.text = email;
    }
    
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
  }
  
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  if (indexPath.section == 0 && indexPath.row == 1) {
    ABPeoplePickerNavigationController *abPicker = [[ABPeoplePickerNavigationController alloc] init];
    abPicker.peoplePickerDelegate = self;
    
    [self presentViewController:abPicker animated:YES completion:nil];

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
  
  NSString *email = @"";
  NSArray *allEmail = (__bridge_transfer NSArray*)ABMultiValueCopyArrayOfAllValues(ABRecordCopyValue(person, kABPersonEmailProperty));
  if ([allEmail count]) {
    email = allEmail[0];
    
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
