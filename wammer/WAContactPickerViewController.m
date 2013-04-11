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
    //TODO: first name then last name, or last name then first name by system settings
    //FIXME: use fullname
    if (_members[indexPath.row][@"firstName"] && _members[indexPath.row][@"lastName"]) {
      cell.textLabel.text = [NSString stringWithFormat:@"%@ %@",
                             _members[indexPath.row][@"firstName"],
                             _members[indexPath.row][@"lastName"]];
    } else if (_members[indexPath.row][@"firstName"]) {
      cell.textLabel.text = _members[indexPath.row][@"firstName"];
                           
    } else if (_members[indexPath.row][@"lastName"]) {
      cell.textLabel.text = _members[indexPath.row][@"lastName"];
      
    }
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@",
                                 _members[indexPath.row][@"phone"],
                                 ([_members[indexPath.row][@"email"] count])? _members[indexPath.row][@"email"][0]: @""];
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
  NSArray *email = (__bridge_transfer NSArray*)ABMultiValueCopyArrayOfAllValues(ABRecordCopyValue(person, kABPersonEmailProperty));
  
  //TODO: pick mobile phone numbers 
  NSString *phone = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(person, kABPersonPhoneProperty), 0);;
  
  NSDictionary *aPerson = @{@"firstName": firstname,
                            @"lastName": lastname,
                            @"email": (email)? email : @[],
                            @"phone": (phone)? phone : @"[N/A]"};

  if (![_members containsObject:aPerson]) {
    [_members addObject:aPerson];
  }
  
}

@end
