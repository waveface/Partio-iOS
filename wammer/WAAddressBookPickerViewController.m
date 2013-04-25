//
//  WAAddressBookPickerViewController.m
//  wammer
//
//  Created by Greener Chen on 13/4/24.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAAddressBookPickerViewController.h"
#import "WAPartioNavigationBar.h"
#import "WAContactPickerSectionHeaderView.h"
#import <AddressBook/AddressBook.h>
#import <AddressBook/ABAddressBook.h>

@interface WAAddressBookPickerViewController() <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (nonatomic, weak) IBOutlet WAPartioNavigationBar *navigationBar;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, strong) NSArray *dataSource;

@end

NSString *kPlaceholderChooseFriends;

@implementation WAAddressBookPickerViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.rightBarButtonItem.enabled = NO;
  
  [self.tableView setBackgroundColor:[UIColor colorWithRed:0.168 green:0.168 blue:0.168 alpha:1]];
  [self.textView setContentSize:self.textView.frame.size];
  kPlaceholderChooseFriends = NSLocalizedString(@"PLACEHOLER_CHOSEN_FRIENDS_ADDRESS_BOOK_PICKER", @"PLACEHOLER_CHOSEN_FRIENDS_ADDRESS_BOOK_PICKER");
  [self.textView setFont:[UIFont fontWithName:@"OpenSans-Regular" size:20.f]];
  [self resetPlaceholder];
  
  __weak WAAddressBookPickerViewController *wSelf = self;
  if (self.navigationController) {
    self.navigationItem.leftBarButtonItem = (UIBarButtonItem*)WABarButtonItem(nil, NSLocalizedString(@"ACTION_CANCEL", @"cancel"), ^{
      if (wSelf.onDismissHandler)
        wSelf.onDismissHandler();
    });
    
    self.navigationItem.rightBarButtonItem = (UIBarButtonItem*)WAPartioToolbarNextButton(@"Share", ^{
      if (self.onNextHandler) {
        if ([_members count]) {
          self.onNextHandler([NSArray arrayWithArray:[self.members copy]]);
        }
        
      }
    });  }
  
  [self.navigationItem setTitle:NSLocalizedString(@"TITLE_INVITE_CONTACTS", @"TITLE_INVITE_CONTACTS")];
  [self.navigationController setNavigationBarHidden:YES];
  [self.navigationItem setHidesBackButton:YES];
  [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
  
  self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
  [self.tap setCancelsTouchesInView:NO];
  [self.view addGestureRecognizer:self.tap];

  self.dataSource = self.contacts;
}

- (void)viewDidAppear:(BOOL)animated
{
  // add joined members into member list
  self.members = [[NSMutableArray alloc] init];
}

- (BOOL) shouldAutorotate {
  return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

- (void)dismissKeyboard
{
  [self.textView setText:@""];
  [self.textView resignFirstResponder];
  [self.tap setCancelsTouchesInView:NO];
  
}

- (UIBarButtonItem *)shareBarButton
{
  return WAPartioToolbarNextButton(@"Share", ^{
    if (self.onNextHandler) {
      self.onNextHandler([NSArray arrayWithArray:self.members]);
    }
  });
}

#pragma mark - text view delegate

- (void)resetPlaceholder
{
  self.textView.text = kPlaceholderChooseFriends;
  self.textView.textColor = [UIColor lightGrayColor];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
  if ([textView.text isEqualToString:kPlaceholderChooseFriends]) {
    textView.text = @"";
    textView.textColor = [UIColor whiteColor];
    [self.textView setFont:[UIFont fontWithName:@"OpenSans-Regular" size:20.f]];
    
    [self.tap setCancelsTouchesInView:YES];
  
  }
}

- (void)textViewDidChange:(UITextView *)textView
{
  if (textView.text) {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
      BOOL result = NO;
      NSString *firstname = (__bridge_transfer NSString*)ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonFirstNameProperty);
      
      if (firstname) {
        if ([firstname rangeOfString:textView.text].location != NSNotFound) {
          result = YES;
          return result;
        }
      }
      
      NSString *lastname = (__bridge_transfer NSString*)ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonLastNameProperty);
      
      if (lastname) {
        if ([lastname rangeOfString:textView.text].location != NSNotFound) {
          result = YES;
          return result;
        }
      }
      
      //FIXME: emailProperty Ref always null
      ABMultiValueRef emailProperty = ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonEmailProperty);
      if (emailProperty) {
        NSArray *emails = (__bridge_transfer NSArray*)ABMultiValueCopyArrayOfAllValues(emailProperty);
        
        NSPredicate *emailSubstring = [NSPredicate predicateWithFormat:@"SELF beginswith %@", textView.text];
        NSArray *searchedEmail = [emails filteredArrayUsingPredicate:emailSubstring];
        if ([searchedEmail count]) {
          result = YES;
          return result;
        }
      }
      
      return result;
      
    }];
    
    NSArray *filteredContacts = [self.contacts filteredArrayUsingPredicate:predicate];
    if ([filteredContacts count]) {
      self.dataSource = filteredContacts;
      [self.tableView reloadData];
    
    } else {
      if ([self NSStringIsValidEmail:textView.text]) {
        NSDictionary *aPerson = @{@"name": textView.text, @"email": @[textView.text]};
        self.dataSource = [NSArray arrayWithObject:aPerson];
        [self.tableView reloadData];
      }
    }
    
  
  } else {
    self.dataSource = self.contacts;
    [self.tableView reloadData];
  }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
  // Reset to placeholder text if the user is done
  // editing and no message has been entered.
  if ([textView.text isEqualToString:@""]) {
    [self resetPlaceholder];
    self.dataSource = self.contacts;
    [self.tableView reloadData];
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

#pragma mark - Table view data source

- (NSArray *)contacts
{
  if (_contacts) {
    return _contacts;
  }
  
  // ABAddressBookRef is used by only one thread
  CFErrorRef Error = NULL;
  ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &Error);
  if (addressBook == NULL) {
    NSLog(@"Address Book Create: %@", Error);
  }
  
  BOOL granted = NO;
  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
      granted = YES;
      
    });
  } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
    granted = YES;

  }
  else {
    // The user has previously denied access
    // Send an alert telling user to change privacy setting in settings app
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"MESSAGE_REQUEST_CONTACT_PERMISSION", @"MESSAGE_REQUEST_CONTACT_PERMISSION") message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"ACTION_OKAY", @"ACTION_OKAY") otherButtonTitles:nil];
    [alert show];
    
    return @[];
  }

  if (granted) {
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(kCFAllocatorDefault,
                                                               CFArrayGetCount(people),
                                                               people);
    CFArraySortValues(peopleMutable,
                      CFRangeMake(0, CFArrayGetCount(people)),
                      (CFComparatorFunction) ABPersonComparePeopleByName,
                      (void*)ABPersonGetSortOrdering());
    
    self.contacts = (__bridge_transfer NSArray *)peopleMutable;
    
    CFRelease(addressBook);
    CFRelease(people);
    
  }
  
  
  return self.contacts;
}

//TODO: table view index
//-(NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
//{
//
//}
//
//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//
//}
//
//- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
//{
//
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  // Return the number of rows in the section.
  return [self.dataSource count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  WAContactPickerSectionHeaderView *headerView = [[WAContactPickerSectionHeaderView alloc] initWithFrame:CGRectMake(0.f, 2.f, 320.f, 22.f)];
  headerView.backgroundColor = tableView.backgroundColor;
  headerView.title.text = NSLocalizedString(@"LABEL_CONTACTS_FRIENDS", @"LABEL_CONTACTS_FRIENDS");
  
  return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  return 24.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
  }
  cell.selectionStyle = UITableViewCellSelectionStyleGray;
  cell.textLabel.textColor = [UIColor whiteColor];
  cell.textLabel.font = [UIFont fontWithName:@"OpenSans-Regular" size:20.f];
  cell.detailTextLabel.font = [UIFont fontWithName:@"OpenSans-Regular" size:12.f];
  
  //TODO: fetch local contact's avatar
  static UIImage *avatar;
  avatar = [UIImage imageNamed:@"Avatar"];
  cell.imageView.image = avatar;
  
  ABRecordRef person = (__bridge ABRecordRef)self.dataSource[indexPath.row]; // get address book record
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
  
  cell.textLabel.text = name;
  
  cell.detailTextLabel.text = @"";
  NSMutableArray *emails = [[NSMutableArray alloc] init];
  CFErrorRef Error = nil;
  ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &Error);
  if (addressBook == NULL) {
    NSLog(@"Address Book Create: %@", Error);
  }
  ABRecordID personID = ABRecordGetRecordID(person);
  ABMultiValueRef emailRef = ABRecordCopyValue(ABAddressBookGetPersonWithRecordID(addressBook, personID), kABPersonEmailProperty);
  
  if (ABMultiValueGetCount(emailRef)) {
    CFArrayRef allEmail = ABMultiValueCopyArrayOfAllValues(emailRef);
    if (CFArrayGetCount(allEmail)) {
      emails = [NSMutableArray arrayWithArray:(__bridge NSMutableArray*)allEmail];
      cell.detailTextLabel.text = emails[0];
      
      if ([name isEqualToString:@""]) {
        cell.textLabel.text = emails[0];
        cell.detailTextLabel.text = @"";
      }
      
    }
    CFRelease(addressBook);
    CFRelease(allEmail);
    CFRelease(emailRef);
    
  }
  
  static UIImage *checkmark;
  checkmark = [UIImage imageNamed:@"Checked"];
  cell.accessoryType = UITableViewCellAccessoryCheckmark;
  cell.accessoryView = [[UIImageView alloc] initWithImage:checkmark];
  
  NSDictionary *aPerson = @{@"name": name, @"email": emails};
  if ([self.members containsObject:aPerson]) {
    cell.accessoryView.hidden = NO;
  } else {
    cell.accessoryView.hidden = YES;
  }
  
  return cell;
}

#pragma mark - table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 54;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  NSString *name = cell.textLabel.text;
  ABRecordRef person = (__bridge ABRecordRef)([self.dataSource objectAtIndex:indexPath.row]);
  
  NSMutableArray *emails = [[NSMutableArray alloc] init];
  CFErrorRef Error = nil;
  ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &Error);
  if (addressBook == NULL) {
    NSLog(@"Address Book Create: %@", Error);
  }
  ABRecordID personID = ABRecordGetRecordID(person);
  ABMultiValueRef emailRef = ABRecordCopyValue(ABAddressBookGetPersonWithRecordID(addressBook, personID), kABPersonEmailProperty);
  
  if (ABMultiValueGetCount(emailRef)) {
    CFArrayRef allEmail = ABMultiValueCopyArrayOfAllValues(emailRef);
    if (CFArrayGetCount(allEmail)) {
      emails = [NSMutableArray arrayWithArray:(__bridge NSMutableArray*)allEmail];
      
    }     
    CFRelease(addressBook);
  }
  NSDictionary *aPerson = @{@"name": name, @"email": emails};
  
  if (cell.accessoryView.hidden) {
    if (![self.members containsObject:aPerson]) {
      [self.members addObject:aPerson];
      
      if (![self.dataSource isEqual:self.contacts]) {
        self.dataSource = self.contacts;
        [self.tableView reloadData];
      }      
      
      NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:[self.contacts indexOfObject:(__bridge id)(person)] inSection:0];
      [self.tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
      
      
    }

    if ([self.members count]) {
      self.navigationItem.rightBarButtonItem.enabled = YES;
      self.navigationItem.title = [NSString stringWithFormat:([self.members count] == 1)? NSLocalizedString(@"TITLE_INVITATION_NUMBER_ONE", @"TITLE_INVITATION_NUMBER_ONE"): NSLocalizedString(@"TITLE_INVITATION_NUMBERS", @"TITLE_INVITATION_NUMBERS"), [self.members count]];
    }

    cell.accessoryView.hidden = NO;
    
  } else {
    cell.accessoryView.hidden = YES;
    
    if ([self.members containsObject:aPerson]) {
      [self.members removeObject:aPerson];
    }
    
    if (![self.members count]) {
      self.navigationItem.rightBarButtonItem.enabled = NO;
      self.navigationItem.title = NSLocalizedString(@"TITLE_INVITE_CONTACTS", @"TITLE_INVITE_CONTACTS");
    }

  }
  
}

@end
