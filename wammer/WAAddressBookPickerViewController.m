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
#import <SMCalloutView/SMCalloutView.h>
#import <BlocksKit/BlocksKit.h>

@interface WAAddressBookPickerViewController() <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIActionSheetDelegate>

@property (nonatomic, weak) IBOutlet WAPartioNavigationBar *navigationBar;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) NSMutableArray *contacts;
@property (nonatomic, strong) NSArray *dataDisplay;
@property (nonatomic, assign) ABAddressBookRef addressBook;
@property (nonatomic, strong) NSMutableArray *filteredContacts;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) SMCalloutView *inviteInstructionView;
@property (nonatomic, assign) ABRecordRef selectedPerson;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end

static NSString const *kPlaceholderChooseFriends;
static NSString const *kWAAddressBookViewController_CoachMarks = @"kWAAddressBookViewController_CoachMarks";

@implementation WAAddressBookPickerViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  BOOL coachmarkShown = [[NSUserDefaults standardUserDefaults] boolForKey:kWAAddressBookViewController_CoachMarks];
  if (!coachmarkShown) {
    __weak WAAddressBookPickerViewController *wSelf = self;
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
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWAAddressBookViewController_CoachMarks];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }

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
  
  self.dataDisplay = self.contacts;
}

- (void)viewDidAppear:(BOOL)animated
{
  // add joined members into member list
  self.members = [[NSMutableArray alloc] init];
  self.filteredContacts = [[NSMutableArray alloc] init];
  
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

- (void)dismissKeyboard
{
  [self.textField setText:@""];
  [self.textField resignFirstResponder];
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

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
  if (self.inviteInstructionView) {
    [self.inviteInstructionView dismissCalloutAnimated:YES];
    self.inviteInstructionView = nil;
    [self.view removeGestureRecognizer:self.tapGesture];
    self.tapGesture = nil;
  }
}

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
      
      NSArray *emails = [self emailsOfPerson:(__bridge ABRecordRef)evaluatedObject];
      
      NSPredicate *emailSubstring = [NSPredicate predicateWithFormat:@"SELF beginswith %@", textInput];
      NSArray *searchedEmail = [emails filteredArrayUsingPredicate:emailSubstring];
      if ([searchedEmail count]) {
        result = YES;
        return result;
      }
      
      return result;
    }];
    
    self.filteredContacts = [NSMutableArray array];
    for (NSArray *section in self.contacts) {
      NSMutableArray *filteredItems = [[section filteredArrayUsingPredicate:predicate] mutableCopy];
      [self.filteredContacts addObject:filteredItems];
    }
    self.dataDisplay = self.filteredContacts;
    [self.tableView reloadData];
    
    if (![self filteredContatcsCount]) {
      if ([self NSStringIsValidEmail:textInput]) {
        ABRecordRef aPerson = ABPersonCreate();
        CFErrorRef Error = NULL;
        ABMutableMultiValueRef emailMutableValue = ABMultiValueCreateMutable(kABPersonEmailProperty);
        ABMultiValueAddValueAndLabel(emailMutableValue, (__bridge CFStringRef)textInput, (__bridge CFStringRef)@"Email", NULL);
        ABRecordSetValue(aPerson, kABPersonEmailProperty, emailMutableValue, &Error);
        NSInteger section = [[UILocalizedIndexedCollation currentCollation] sectionForObject:textInput collationStringSelector:@selector(self)];
        [self.filteredContacts[section] insertObject:(__bridge id)aPerson atIndex:0];
        self.dataDisplay = self.filteredContacts;
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
    NSInteger section;
    for (section = 0; section < [self.dataDisplay count]; section++) {
      if ([self.dataDisplay[section] count]) {
        if (![self contactsContainPerson:self.dataDisplay[section][0] inSection:section]) {
          [self.contacts[section] insertObject:self.dataDisplay[section][0] atIndex:0];
          break;
        }
      }    
    }
    self.dataDisplay = self.contacts;
    [self.tableView reloadData];
    
    if ([self filteredContatcsCount]) {
      ABRecordRef person = (__bridge ABRecordRef)(self.filteredContacts[section][0]);
      NSString *firstname = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
      NSString *lastname = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
      NSString *name = [self compositeNameFormatWithFirstname:firstname lastname:lastname];
      NSArray *emails = [self emailsOfPerson:person];
      
      NSDictionary *aPerson;
      if ([emails count]) {
        aPerson = @{@"name": name, @"email": @[emails[0]]};
      } else {
        aPerson = @{@"name": name, @"email": @[]};
      }
      
      if (![self.members containsObject:aPerson]) {
        [self.members addObject:aPerson];
        
        CFErrorRef Error = NULL;
        ABAddressBookAddRecord(self.addressBook, person, &Error);
        
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];
        [self.tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        [self.tableView reloadRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [[self.toolbar.items objectAtIndex:1] setEnabled:YES];
        [self updateNavigationBarTitle];
        
      }
    }

    self.filteredContacts = [NSMutableArray array];
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

- (BOOL)contactsContainPerson:(id)object inSection:(NSInteger)section
{
  ABRecordRef targetPerson = (__bridge ABRecordRef)object;
  for (id obj in self.contacts[section]) {
    ABRecordRef person = (__bridge ABRecordRef)obj;
    if (targetPerson == person) {
      return YES;
    }
  }
  
  return NO;
}

- (NSInteger)filteredContatcsCount
{
  NSInteger filteredCount = 0;
  for (NSInteger i = 0; i < [self.filteredContacts count]; i++) {
    filteredCount += [self.filteredContacts[i] count];
  }
  
  return filteredCount;
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
    
    
  }
  
  //self.contacts = [self omitFacebookContacts:self.contacts];
  self.contacts = [self sectionObjects:self.contacts collationStringSelector:@selector(self)];
  
  return self.contacts;
}

- (NSMutableArray *)omitFacebookContacts:(NSArray *)contacts
{
  //TODO: omit contacts from Facebook source
  NSMutableArray *filteredContacts = [NSMutableArray array];
  for (id object in contacts) {
    ABRecordRef person = (__bridge ABRecordRef)object;
    NSString *name = (__bridge NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    ABRecordRef sourceType = ABPersonCopySource(person);
    if ([(__bridge NSNumber *)sourceType intValue] != 4) {
      [filteredContacts addObject:object];
    }
  }
  
  return filteredContacts;
}

- (NSMutableArray *)sectionObjects:(NSArray *)objects collationStringSelector:(SEL)selector
{
  UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
  
  NSInteger sectionCount = [[collation sectionTitles] count];
  NSMutableArray *unsortedSections = [NSMutableArray arrayWithCapacity:sectionCount];
  for (NSInteger i = 0; i < sectionCount; i++) {
    [unsortedSections addObject:[NSMutableArray array]];
  }
  
  for (id object in objects) {
    ABRecordRef person = (__bridge ABRecordRef)(object);
    NSString *name = (__bridge NSString *)ABRecordCopyCompositeName(person);
    NSArray *emails = [self emailsOfPerson:person];
    
    NSInteger index;
    if (!name || [name isEqualToString:@""]) {
      if ([emails count]) {
        index = [collation sectionForObject:emails[0] collationStringSelector:selector];
        [unsortedSections[index] addObject:object];
      }      
    } else {
      index = [collation sectionForObject:name collationStringSelector:selector];
      [unsortedSections[index] addObject:object];
    }
  }

  NSMutableArray *sortedSections = [NSMutableArray arrayWithCapacity:sectionCount];
  for (NSMutableArray *section in unsortedSections) {
    NSMutableArray *sectionNames = [NSMutableArray array];
    for (id object in section) {
      ABRecordRef person = (__bridge ABRecordRef)object;
      NSString *name = (__bridge NSString *)ABRecordCopyCompositeName(person);
      NSArray *emails = [self emailsOfPerson:person];
      
      if (!name || [name isEqualToString:@""]) {
        if ([emails count]) {
          [sectionNames addObject:emails[0]];
        }
      } else {
        [sectionNames addObject:name];
      }
    }
    
    NSArray *sortedNames = [collation sortedArrayFromArray:sectionNames collationStringSelector:selector];
    NSMutableArray *sortedSection = [NSMutableArray arrayWithCapacity:[sortedNames count]];
    for (NSInteger i = 0; i < [sortedNames count]; i++) {
      NSInteger index = [self indexOfPerson:sortedNames[i] InArray:section];
      if (index > 0) {
        [sortedSection addObject:section[index]];
      }    
    }
    
    [sortedSections addObject:sortedSection];
  }
  
  return sortedSections;
}

- (NSArray *)emailsOfPerson:(ABRecordRef)person
{
  NSMutableArray *emails = [[NSMutableArray alloc] init];
  ABRecordID personID = ABRecordGetRecordID(person);
  
  ABMultiValueRef emailRef = NULL;
  if (personID < 0) {
    emailRef = ABRecordCopyValue(person, kABPersonEmailProperty);
  } else {
    emailRef = ABRecordCopyValue(ABAddressBookGetPersonWithRecordID(self.addressBook, personID), kABPersonEmailProperty);
  }
  
  if (ABMultiValueGetCount(emailRef)) {
    CFArrayRef allEmail = ABMultiValueCopyArrayOfAllValues(emailRef);
    if (CFArrayGetCount(allEmail)) {
      emails = [NSMutableArray arrayWithArray:(__bridge NSMutableArray*)allEmail];
    }
    
    CFRelease(allEmail);
    CFRelease(emailRef);
  }

  return emails;
}

- (NSInteger)indexOfPerson:(NSString *)targetName InArray:(NSArray *)array
{
  for (NSInteger i = 0; i < [array count]; i++) {
    ABRecordRef person = (__bridge ABRecordRef)array[i];
    NSString *name = (__bridge NSString *)ABRecordCopyCompositeName(person);
    NSArray *emails = [self emailsOfPerson:person];
    
    if (!name || [name isEqualToString:@""]) {
      if ([emails count]) {
        if ([emails[0] isEqualToString:targetName]) {
          return i;
        }
      }
    } else {
      if ([name isEqualToString:targetName]) {
        return i;
      }
    }   
  }
  
  return -1;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
  NSMutableArray *titles = [[[UILocalizedIndexedCollation currentCollation] sectionTitles] mutableCopy];
  for (NSInteger i = 0; i < [titles count]; i++) {
    NSArray *words = [titles[i] componentsSeparatedByString:@" "];
    titles[i] = words[0];
  }
  return titles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
  NSArray *sectionTitles = [self sectionIndexTitlesForTableView:self.tableView];
  if (index < [sectionTitles count]) {
    NSString *sectionTitle = [sectionTitles objectAtIndex:index];
    if ([sectionTitle isEqualToString:title]) {
      return index;
    }
  }
  
  return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  // Return the number of rows in the section.
  if ([self.dataDisplay count]) {
    return [self.dataDisplay[section] count];
  } else {
    return 0;
  }
  
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  WAContactPickerSectionHeaderView *headerView = [[WAContactPickerSectionHeaderView alloc] initWithFrame:CGRectMake(0.f, 2.f, 320.f, 22.f)];
  headerView.backgroundColor = tableView.backgroundColor;
  //headerView.title.text = NSLocalizedString(@"LABEL_CONTACTS_FRIENDS", @"LABEL_CONTACTS_FRIENDS");
  
  headerView.title.text = [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section];
  
  return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  if ([self.dataDisplay count] > section) {
    if ([self.dataDisplay[section] count]) {
      return 22.f;
    } else {
      return 0.f;
    }
  }
  
  return 0.f;
}

- (UIImage *)scaledImage:(UIImage *)image withSize:(CGSize)size
{
  size = CGSizeMake(size.width - 6.f, size.height - 6.f);
  UIGraphicsBeginImageContext(size);
  [image drawInRect:(CGRect){CGPointZero, size}];
  UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return scaledImage;
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
  
  ABRecordRef person;
  NSArray *section = [self.dataDisplay objectAtIndex:indexPath.section];
  if ([section count]) {
    person = (__bridge ABRecordRef)section[indexPath.row]; // get address book record
  
    static UIImage *defaultAvatar;
    defaultAvatar = [UIImage imageNamed:@"Avatar"];
    cell.imageView.image = defaultAvatar;
    if (ABPersonHasImageData(person)) {
      NSData *data = (__bridge NSData *)ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
      if (data) {
        cell.imageView.image = [self scaledImage:[[UIImage alloc] initWithData:data] withSize:defaultAvatar.size] ;
        
      }
    }
    cell.imageView.layer.cornerRadius = 3.f;
    cell.imageView.clipsToBounds = YES;
    
    NSString *firstname = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *lastname = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
    NSString *name = [self compositeNameFormatWithFirstname:firstname lastname:lastname];
    
    cell.textLabel.text = name;
    
    cell.detailTextLabel.text = @"";
    NSArray *emails = [self emailsOfPerson:person];
    if ([emails count]) {
      cell.detailTextLabel.text = emails[0];
    }
    
    static UIImage *checkmark;
    checkmark = [UIImage imageNamed:@"Checked"];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    cell.accessoryView = [[UIImageView alloc] initWithImage:checkmark];
    
    cell.accessoryView.hidden = YES;
    if ([emails count]) {
      NSDictionary *aPerson;
      for (NSInteger i = 0; i < [emails count]; i++) {
        aPerson = @{@"name": name, @"email": @[emails[i]]};
        
        if ([self.members containsObject:aPerson]) {
          cell.accessoryView.hidden = NO;
          cell.detailTextLabel.text = emails[i];
        }
      }
    }
    
  }
  
  return cell;
}

- (NSString *)compositeNameFormatWithFirstname:(NSString *)firstname lastname:(NSString *)lastname
{
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
  
  return name;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
  if (section != [tableView numberOfSections] - 1) {
    return 0.f;
  } else {
    return 44.f;
  }
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

  if (self.inviteInstructionView) {
    [self.inviteInstructionView dismissCalloutAnimated:YES];
    self.inviteInstructionView = nil;
    [self.view removeGestureRecognizer:self.tapGesture];
    self.tapGesture = nil;
  }
  
  if ([self.textField isFirstResponder]) {
    [self.textField setText:@""];
    [self.textField resignFirstResponder];
  }

  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  NSString *name = cell.textLabel.text;
  
  ABRecordRef person = (__bridge ABRecordRef)self.contacts[indexPath.section][indexPath.row];
  if ([self filteredContatcsCount]) {
    person = (__bridge ABRecordRef)self.filteredContacts[indexPath.section][indexPath.row];
    
  }
  
  NSArray *emails = [self emailsOfPerson:person];
  NSDictionary *aPerson;
  if ([emails count]) {
    aPerson = @{@"name": name, @"email": @[emails[0]]};
  } else {
    aPerson = @{@"name": name, @"email": @[]};
  }
  
  if (cell.accessoryView.hidden) {
    
    if (![emails count]) {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"MESSAGE_NO_EMAIL_CONTACT", @"MESSAGE_NO_EMAIL_CONTACT") message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"ACTION_OKAY", @"ACTION_OKAY") otherButtonTitles:nil];
      
      [alert show];
      return;
    
    } else if ([emails count] > 1) {
      self.selectedPerson = person;
      self.selectedIndexPath = indexPath;
      UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:name];
      as.delegate = self;
      for (NSInteger i = 0; i < [emails count]; i++) {
        [as addButtonWithTitle:emails[i]];
      }
      [as setCancelButtonWithTitle:NSLocalizedString(@"ACTION_CANCEL", @"ACTION_CANCEL") handler:^{
        return;
      }];
      [as setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
      [as showFromToolbar:self.toolbar];
      
      return;
    }
    
    if (![self.members containsObject:aPerson]) {
      [self.members addObject:aPerson];
      cell.accessoryView.hidden = NO;
      
      self.dataDisplay = self.contacts;
      [self.tableView reloadData];
      
      if ([self filteredContatcsCount]) {
        [self scrollToSelectedPerson:person];
        self.filteredContacts = [NSMutableArray array];
      }       
    }
  
    if ([self.members count]) {
      [[self.toolbar.items objectAtIndex:1] setEnabled:YES];
      [self updateNavigationBarTitle];
    }
    
  } else {
    cell.accessoryView.hidden = YES;
    
    if ([emails count]) {
      NSDictionary *aPerson;
      for (NSInteger i = 0; i < [emails count]; i++) {
        aPerson = @{@"name": name, @"email": @[emails[i]]};
        
        if ([self.members containsObject:aPerson]) {
          [self.members removeObject:aPerson];
          
          [tableView reloadData];
          if ([self filteredContatcsCount]) {
            [self scrollToSelectedPerson:person];
            self.filteredContacts = [NSMutableArray array];
          }

          [self updateNavigationBarTitle];

        }
      }
    }
    

  }
 
}

- (void)scrollToSelectedPerson:(ABRecordRef)person
{
  NSIndexPath *newIndexPath;
  for (NSInteger i = 0; i < [self.contacts count]; i++) {
    if ([self.contacts[i] count]) {
      for (NSInteger j = 0; j < [self.contacts[i] count]; j++) {
        if (person == (__bridge ABRecordRef)self.contacts[i][j]) {
          newIndexPath = [NSIndexPath indexPathForRow:j inSection:i];
        }
      }
    }
  }
  [self.tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  NSString *firstname = (__bridge_transfer NSString*)ABRecordCopyValue(self.selectedPerson, kABPersonFirstNameProperty);
  NSString *lastname = (__bridge_transfer NSString*)ABRecordCopyValue(self.selectedPerson, kABPersonLastNameProperty);
  NSString *name = [self compositeNameFormatWithFirstname:firstname lastname:lastname];
  NSMutableArray *emails = [[self emailsOfPerson:self.selectedPerson] mutableCopy];
  
  if (buttonIndex == [emails count]) {
    return;
  }
  
  NSString *selectedEmail = emails[buttonIndex];
  [emails removeObjectAtIndex:buttonIndex];
  [emails insertObject:selectedEmail atIndex:0];
  
  NSDictionary *aPerson = @{@"name":name, @"email":@[emails[0]]};
  UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.selectedIndexPath];
  if (cell.accessoryView.hidden) {
    if (![self.members containsObject:aPerson]) {
      [self.members addObject:aPerson];
      
      self.dataDisplay = self.contacts;
      [self.tableView reloadData];
      
      if ([self filteredContatcsCount]) {
        [self scrollToSelectedPerson:self.selectedPerson];
        self.filteredContacts = [NSMutableArray array];
      }
    }
    
    if ([self.members count]) {
      [[self.toolbar.items objectAtIndex:1] setEnabled:YES];
      [self updateNavigationBarTitle];
    }
    
  }
}

@end
