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

@interface WAAddressBookPickerViewController() <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet WAPartioNavigationBar *navigationBar;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) NSMutableArray *contacts;
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, strong) NSArray *dataDisplay;
@property (nonatomic, assign) ABAddressBookRef addressBook;
@property (nonatomic, strong) NSArray *filteredContacts;


@end

NSString *kPlaceholderChooseFriends;

@implementation WAAddressBookPickerViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self.tableView setBackgroundColor:[UIColor colorWithRed:0.168 green:0.168 blue:0.168 alpha:1]];
  kPlaceholderChooseFriends = NSLocalizedString(@"PLACEHOLER_CHOSEN_FRIENDS_ADDRESS_BOOK_PICKER", @"PLACEHOLER_CHOSEN_FRIENDS_ADDRESS_BOOK_PICKER");
  [self.textField setPlaceholder:kPlaceholderChooseFriends];
  [self.textField setFont:[UIFont fontWithName:@"OpenSans-Regular" size:18.f]];
  [self.textField setLeftViewMode:UITextFieldViewModeAlways];
  [self.textField setLeftView:[[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 10.f, 44.f)]];
   
  __weak WAAddressBookPickerViewController *wSelf = self;
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
  
  self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
  [self.tap setCancelsTouchesInView:NO];
  [self.view addGestureRecognizer:self.tap];

  self.dataDisplay = self.contacts;
}

- (void)viewDidAppear:(BOOL)animated
{
  // add joined members into member list
  self.members = [[NSMutableArray alloc] init];
  self.filteredContacts = [[NSArray alloc] init];
  
}

- (BOOL) shouldAutorotate {
  return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

- (void)dismissKeyboard
{
  [self.textField setText:@""];
  [self.textField resignFirstResponder];
  [self.tap setCancelsTouchesInView:NO];
  self.dataDisplay = self.contacts;
  [self.tableView reloadData];
}

- (UIBarButtonItem *)shareBarButton
{
  return WAPartioToolbarNextButton(@"Share", ^{
    if (self.onNextHandler) {
      self.onNextHandler([NSArray arrayWithArray:self.members]);
    }
  });
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

#pragma mark - text view delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
  NSString *textInput = @"";
  if (range.length) {
    textInput = [textField.text substringToIndex:range.location];
  } else {
    textInput = [textField.text stringByAppendingString:string];
  }
  
  if (![textInput isEqual:@""]) {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
      BOOL result = NO;
      NSString *firstname = (__bridge_transfer NSString*)ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonFirstNameProperty);
      
      if (firstname) {
        if ([firstname rangeOfString:textInput].location != NSNotFound) {
          result = YES;
          return result;
        }
      }
      
      NSString *lastname = (__bridge_transfer NSString*)ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonLastNameProperty);
      
      if (lastname) {
        if ([lastname rangeOfString:textInput].location != NSNotFound) {
          result = YES;
          return result;
        }
      }
      
      NSMutableArray *emails = [[NSMutableArray alloc] init];
      ABRecordID personID = ABRecordGetRecordID((__bridge ABRecordRef)evaluatedObject);
      
      if (personID < 0) { //manual created record
        emails = [@[firstname] mutableCopy];
      
      } else {
        ABMultiValueRef emailRef = ABRecordCopyValue(ABAddressBookGetPersonWithRecordID(self.addressBook, personID), kABPersonEmailProperty);
        
        if (ABMultiValueGetCount(emailRef)) {
          CFArrayRef allEmail = ABMultiValueCopyArrayOfAllValues(emailRef);
          if (CFArrayGetCount(allEmail)) {
            emails = [NSMutableArray arrayWithArray:(__bridge NSMutableArray*)allEmail];
            
            NSPredicate *emailSubstring = [NSPredicate predicateWithFormat:@"SELF beginswith %@", textInput];
            NSArray *searchedEmail = [emails filteredArrayUsingPredicate:emailSubstring];
            if ([searchedEmail count]) {
              result = YES;
              return result;
            }
          }
          CFRelease(allEmail);
          CFRelease(emailRef);
        }
      }
      
      return result;
      
    }];
    
    self.filteredContacts = [self.contacts filteredArrayUsingPredicate:predicate];
    self.dataDisplay = self.filteredContacts;
    [self.tableView reloadData];
    
    if (![self.filteredContacts count]) {
      if ([self NSStringIsValidEmail:textInput]) {
        ABRecordRef aPerson = ABPersonCreate();
        CFErrorRef Error = NULL;
        ABRecordSetValue(aPerson, kABPersonFirstNameProperty, (__bridge CFStringRef)textInput, &Error);
        ABMutableMultiValueRef emailMutableValue = ABMultiValueCreateMutable(kABPersonEmailProperty);
        ABMultiValueAddValueAndLabel(emailMutableValue, (__bridge CFStringRef)textInput, (__bridge CFStringRef)@"Email", NULL);
        ABRecordSetValue(aPerson, kABPersonEmailProperty, emailMutableValue, &Error);
        self.dataDisplay = [NSArray arrayWithObject:(__bridge id)(aPerson)];
        [self.tableView reloadData];
      }
    }
    
  
  } else {
    self.dataDisplay = self.contacts;
    [self.tableView reloadData];
  }
  
  return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
  if ([self NSStringIsValidEmail:textField.text]) {
    self.filteredContacts = [NSArray arrayWithArray:self.dataDisplay];
    CFArrayRef people = (__bridge CFArrayRef)self.contacts;
    CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(kCFAllocatorDefault,
                                                               CFArrayGetCount(people),
                                                               people);
    CFArrayAppendValue(peopleMutable, (__bridge const void *)(self.dataDisplay[0]));
    CFArraySortValues(peopleMutable,
                      CFRangeMake(0, CFArrayGetCount(people)),
                      (CFComparatorFunction) ABPersonComparePeopleByName,
                      (void*)ABPersonGetSortOrdering());
    self.contacts = (__bridge NSMutableArray *)peopleMutable;
    self.dataDisplay = self.contacts;
    [self.tableView reloadData];
    
    ABRecordRef person = (__bridge ABRecordRef)(self.filteredContacts[0]);
    NSString *firstname = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSMutableArray *emails = [NSMutableArray arrayWithObject:firstname];
    
    NSDictionary *aPerson = @{@"name": firstname, @"email": emails};
    if (![self.members containsObject:aPerson]) {
      [self.members addObject:aPerson];
      
      NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:[self.contacts indexOfObject:(__bridge id)(person)] inSection:0];
      
      if (!newIndexPath.row) {
        [self.tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        
      } else if (newIndexPath.row == [self.contacts count] - 1) {
        [self.tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        
      } else {
        [self.tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        
      }
   
      [[self.toolbar.items objectAtIndex:1] setEnabled:NO];
      [self updateNavigationBarTitle];
      
    }
    
    self.filteredContacts = @[];
    textField.text = @"";
    
  } else if ([textField.text isEqualToString:@""]) {
    self.dataDisplay = self.contacts;
    
  }  
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  
  return YES;
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
  self.addressBook = ABAddressBookCreateWithOptions(NULL, &Error);
  if (self.addressBook == NULL) {
    NSLog(@"Address Book Create: %@", Error);
  }
  
  BOOL granted = NO;
  if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
    ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
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
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(self.addressBook);
    CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(kCFAllocatorDefault,
                                                               CFArrayGetCount(people),
                                                               people);
    CFArraySortValues(peopleMutable,
                      CFRangeMake(0, CFArrayGetCount(people)),
                      (CFComparatorFunction) ABPersonComparePeopleByName,
                      (void*)ABPersonGetSortOrdering());
    
    self.contacts = [(__bridge_transfer NSArray *)peopleMutable copy];
    
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
  return [self.dataDisplay count];
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
  
  ABRecordRef person = (__bridge ABRecordRef)self.dataDisplay[indexPath.row]; // get address book record
  
  static UIImage *defaultAvatar;
  defaultAvatar = [UIImage imageNamed:@"Avatar"];
  cell.imageView.image = defaultAvatar;
  cell.imageView.frame = CGRectMake(CGRectGetWidth(cell.imageView.frame)/2.f - defaultAvatar.size.width/2.f,
                                    CGRectGetHeight(cell.imageView.frame)/2.f - defaultAvatar.size.height/2.f,
                                    defaultAvatar.size.width,
                                    defaultAvatar.size.height);
  if (ABPersonHasImageData(person)) {
    NSData *data = (__bridge NSData *)ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
    if (data) {
      cell.imageView.image = [[UIImage alloc] initWithData:data];
    }
  }
  cell.imageView.layer.cornerRadius = 3.f;
  cell.imageView.clipsToBounds = YES;
  
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
  ABRecordID personID = ABRecordGetRecordID(person);
  
  if (personID < 0) {
    emails = [NSMutableArray arrayWithObject:name];
  
  } else {
    ABMultiValueRef emailRef = ABRecordCopyValue(ABAddressBookGetPersonWithRecordID(self.addressBook, personID), kABPersonEmailProperty);
    
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
      
      CFRelease(allEmail);
      CFRelease(emailRef);
      
    }
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

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
  return 44.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, CGRectGetWidth(tableView.frame), 44.f)];
  [view setBackgroundColor:[UIColor clearColor]];
  
  return view;
}

#pragma mark - table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 54;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  [self.tap setCancelsTouchesInView:YES];
  
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  NSString *name = cell.textLabel.text;
  
  ABRecordRef person = (__bridge ABRecordRef)self.contacts[indexPath.row];
  if ([self.filteredContacts count]) {
    person = (__bridge ABRecordRef)self.filteredContacts[indexPath.row];
    
  }
  
  NSMutableArray *emails = [[NSMutableArray alloc] init];
  ABRecordID personID = ABRecordGetRecordID(person);
  
  if (personID < 0) { // manual created record
    emails = [NSMutableArray arrayWithObject:name];
  
  } else {
    ABMultiValueRef emailRef = ABRecordCopyValue(ABAddressBookGetPersonWithRecordID(self.addressBook, personID), kABPersonEmailProperty);
    
    if (ABMultiValueGetCount(emailRef)) {
      CFArrayRef allEmails = ABMultiValueCopyArrayOfAllValues(emailRef);
      if (CFArrayGetCount(allEmails)) {
        emails = [NSMutableArray arrayWithArray:(__bridge NSMutableArray*)allEmails];
        
      }
    }
  }
  
  NSDictionary *aPerson = @{@"name": name, @"email": emails};
  
  if (cell.accessoryView.hidden) {
    
    if ([aPerson[@"email"] isEqual:@[]]) {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"MESSAGE_NO_EMAIL_CONTACT", @"MESSAGE_NO_EMAIL_CONTACT") message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"ACTION_OKAY", @"ACTION_OKAY") otherButtonTitles:nil];
      
      [alert show];
      return;
    }
    
    if (![self.members containsObject:aPerson]) {
      [self.members addObject:aPerson];
      cell.accessoryView.hidden = NO;
      
      self.dataDisplay = self.contacts;
      [self.tableView reloadData];
      
      if ([self.filteredContacts count]) {
        [self scrollToSelectedPerson:person];
        self.filteredContacts = @[];
      }       
    }
  
    if ([self.members count]) {
      [[self.toolbar.items objectAtIndex:1] setEnabled:YES];
      [self updateNavigationBarTitle];
    }
    
  } else {
    cell.accessoryView.hidden = YES;
    
    if ([self.members containsObject:aPerson]) {
      [self.members removeObject:aPerson];
      
      if ([self.filteredContacts count]) {
        [self scrollToSelectedPerson:person];
        self.filteredContacts = @[];
      }
      
    }
    
    [self updateNavigationBarTitle];

  }
  
}

- (void)scrollToSelectedPerson:(ABRecordRef)person
{
  NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:[self.contacts indexOfObject:(__bridge id)(person)] inSection:0];
  [self.tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

@end
