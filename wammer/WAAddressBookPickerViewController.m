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

@interface WAAddressBookPickerViewController() <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (nonatomic, weak) IBOutlet WAPartioNavigationBar *navigationBar;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, assign) NSArray *contacts;

@end

NSString *kPlaceholderChooseFriends;

@implementation WAAddressBookPickerViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self.tableView setBackgroundColor:[UIColor colorWithRed:0.168 green:0.168 blue:0.168 alpha:1]];
  [self.textView setBackgroundColor:[UIColor darkGrayColor]];
  kPlaceholderChooseFriends = NSLocalizedString(@"PLACEHOLER_CHOSEN_FRIENDS_ADDRESSBOOKPICKER", @"PLACEHOLER_CHOSEN_FRIENDS_ADDRESSBOOKPICKER");
  [self resetPlaceholder];
  
  __weak WAAddressBookPickerViewController *wSelf = self;
  if (self.navigationController) {
    self.navigationItem.leftBarButtonItem = (UIBarButtonItem*)WABarButtonItem(nil, NSLocalizedString(@"ACTION_CANCEL", @"cancel"), ^{
      if (wSelf.onDismissHandler)
        wSelf.onDismissHandler();
    });
    
    self.navigationItem.rightBarButtonItem = (UIBarButtonItem*)WABarButtonItem(nil, NSLocalizedString(@"ACTION_DONE", @"ACTION_DONE"), ^{
      
    });
  }
  [self.navigationItem setTitle:NSLocalizedString(@"TITLE_ADDRESS_BOOK_PICKER", @"TITLE_ADDRESS_BOOK_PICKER")];
  
  [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
  
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
  }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
  // Reset to placeholder text if the user is done
  // editing and no message has been entered.
  if ([textView.text isEqualToString:@""]) {
    [self resetPlaceholder];
  }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *) event
{
  UITouch *touch = [[event allTouches] anyObject];
  if ([self.textView isFirstResponder] &&
      (self.textView != touch.view))
  {
    [self.textView resignFirstResponder];
  }
}

#pragma mark - Table view data source

- (NSArray *)contacts
{
  if (_contacts) {
    return _contacts;
  }
  
  //TODO: ABAddressBookRef is used by only one thread
  dispatch_async(dispatch_get_main_queue(), ^{
    CFErrorRef Error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &Error);
    if (addressBook == NULL) {
      NSLog(@"Address Book Create: %@", Error);
    }
    
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(kCFAllocatorDefault,
                                                               CFArrayGetCount(people),
                                                               people);
    CFArraySortValues(peopleMutable,
                      CFRangeMake(0, CFArrayGetCount(people)),
                      (CFComparatorFunction) ABPersonComparePeopleByName,
                      (void*)ABPersonGetSortOrdering());
    
    self.contacts = [NSArray arrayWithArray:(__bridge_transfer NSArray *)peopleMutable];
    
    CFRelease(addressBook);
    CFRelease(people);
    CFRelease(peopleMutable);
  });
  
  
  return self.contacts;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  // Return the number of rows in the section.
  return self.contacts.count;
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
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
  static UIImage *avatar;
  avatar = [UIImage imageNamed:@"Avatar"];
  cell.imageView.image = avatar;
  
  for (id object in self.contacts)
  {
    ABRecordRef person = (__bridge ABRecordRef)object; // get address book record
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
      if ([name isEqualToString:@""]) {
        name = allEmail[0];
      }
      
    }
    cell.textLabel.text = email[0];
  }
  
  static UIImage *checkmark;
  checkmark = [UIImage imageNamed:@"Checked"];
  cell.accessoryType = UITableViewCellAccessoryCheckmark;
  cell.accessoryView = [[UIImageView alloc] initWithImage:checkmark];
  cell.accessoryView.hidden = YES;
  
  return cell;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  if (cell.accessoryView.hidden) {
    cell.accessoryView.hidden = NO;
  
  } else {
    cell.accessoryView.hidden = YES;
    
  }
  
}

@end
