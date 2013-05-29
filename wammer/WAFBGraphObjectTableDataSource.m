//
//  WAFBGraphObjectTableDataSource.m
//  wammer
//
//  Created by Greener Chen on 13/5/16.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAFBGraphObjectTableDataSource.h"
#import "WAFBGraphObjectTableCell.h"
#import <FBURLConnection.h>
#import <FBUtility.h>
#import "WAFBGraphUser.h"

// Magic number - iPhone address book doesn't show scrubber for less than 5 contacts
static const NSInteger kMinimumCountToCollate = 6;
static const NSInteger kMaximumCountOfListedRecentFriends = 5;
static NSString *indexKeyOfRecentUsedContacts = @"★";

@interface WAFBGraphObjectTableDataSource()

@property (nonatomic, retain) NSArray *data;
@property (nonatomic, retain) NSArray *indexKeys;
@property (nonatomic, retain) UILocalizedIndexedCollation *collation;
@property (nonatomic, assign) BOOL showSections;
@property (nonatomic, assign) BOOL expectingMoreGraphObjects;
@property (nonatomic, retain) NSMutableArray *storedFriendList;
@property (nonatomic, retain) NSMutableArray *recentFriendImageShown;

- (WAFBGraphObjectTableCell *)cellWithTableView:(UITableView *)tableView;
- (BOOL)filterIncludesItem:(FBGraphObject *)item;
- (UIImage *)tableView:(UITableView *)tableView imageForItem:(FBGraphObject *)item;
- (NSString *)indexKeyOfItem:(FBGraphObject *)item;
- (void)addOrRemovePendingConnection:(FBURLConnection *)connection;
- (BOOL)isActivityIndicatorIndexPath:(NSIndexPath *)indexPath;

@end

@implementation WAFBGraphObjectTableDataSource

- (id)init
{
  self = [super init];
  if (self) {
    self.storedFriendList = [[[NSUserDefaults standardUserDefaults] arrayForKey:kFrequentFriendList] mutableCopy];
    
    id object = @NO;
    NSMutableArray *buffer = [NSMutableArray arrayWithCapacity:kMaximumCountOfListedRecentFriends];
    for (NSInteger i = 0; i < kMaximumCountOfListedRecentFriends; i++) {
      buffer[i] = object;
    }
    self.recentFriendImageShown = [NSMutableArray arrayWithArray:buffer];
    
  }
  return self;
}

- (void)bindTableView:(UITableView *)tableView
{
  tableView.dataSource = self;
  tableView.rowHeight = [WAFBGraphObjectTableCell rowHeight];
}

- (WAFBGraphObjectTableCell *)cellWithTableView:(UITableView *)tableView
{
  static NSString * const cellKey = @"WAFBTableCell";
  WAFBGraphObjectTableCell *cell =
  (WAFBGraphObjectTableCell*)[tableView dequeueReusableCellWithIdentifier:cellKey];
  
  if (!cell) {
    cell = [[WAFBGraphObjectTableCell alloc]
            initWithStyle:UITableViewCellStyleSubtitle
            reuseIdentifier:cellKey];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  
  return cell;
}

- (UIImage *)tableView:(UITableView *)tableView imageForItem:(FBGraphObject *)item
{
  __block UIImage *image = nil;
  NSString *urlString = [self.controllerDelegate graphObjectTableDataSource:self
                                                           pictureUrlOfItem:item];
  if (urlString) {
    FBURLConnectionHandler handler =
    ^(FBURLConnection *connection, NSError *error, NSURLResponse *response, NSData *data) {
      [self addOrRemovePendingConnection:connection];
      if (!error) {
        image = [UIImage imageWithData:data];
        
        if (self.storedFriendList.count) {
          NSArray *storedItems = [self.storedFriendList valueForKey:@"fbFriend"];
          NSMutableArray *recentUsedFBFriends = [NSMutableArray array];
          for (id item in storedItems) {
            if ([item isKindOfClass:[NSDictionary class]]) { // convert saved NSDictionary back to FBGraphObject
              [recentUsedFBFriends addObject:[FBGraphObject graphObjectWrappingDictionary:item]];
              
            }
          }
          
          NSRange limits;
          limits.location = 0;
          limits.length = kMaximumCountOfListedRecentFriends;
          NSArray *limitedRecentUsedFBFriends = (recentUsedFBFriends.count > kMaximumCountOfListedRecentFriends)?[recentUsedFBFriends subarrayWithRange:limits]:recentUsedFBFriends;
    
          if ([limitedRecentUsedFBFriends containsObject:item] &&
              ([[self.recentFriendImageShown objectAtIndex:[limitedRecentUsedFBFriends indexOfObject:item]] isEqual:@NO])) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[limitedRecentUsedFBFriends indexOfObject:item] inSection:0];
            WAFBGraphObjectTableCell *cell = (WAFBGraphObjectTableCell*)[tableView cellForRowAtIndexPath:indexPath];
            
            if (cell) {
              cell.picture = image;
            }
            
            self.recentFriendImageShown[[limitedRecentUsedFBFriends indexOfObject:item]] = @YES;

          } else {
            NSIndexPath *indexPath = [self indexPathForItem:item];
            if (indexPath) {
              WAFBGraphObjectTableCell *cell =
              (WAFBGraphObjectTableCell*)[tableView cellForRowAtIndexPath:indexPath];
              
              if (cell) {
                cell.picture = image;
              }
            }
          }
        }
        
        NSIndexPath *indexPath = [self indexPathForItem:item];
        if (indexPath) {
          WAFBGraphObjectTableCell *cell =
          (WAFBGraphObjectTableCell*)[tableView cellForRowAtIndexPath:indexPath];
          
          if (cell) {
            cell.picture = image;
          }
        }
      }
    };
    
    FBURLConnection *connection = [[FBURLConnection alloc]
                                    initWithURL:[NSURL URLWithString:urlString]
                                    completionHandler:handler];
    
    [self addOrRemovePendingConnection:connection];
  }
  
  // If the picture had not been fetched yet by this object, but is cached in the
  // URL cache, we can complete synchronously above.  In this case, we will not
  // find the cell in the table because we are in the process of creating it. We can
  // just return the object here.
  if (image) {
    return image;
  }
  
  return self.defaultPicture;
}

// Called after changing any properties.  To simplify the code here,
// since this class is internal, we do not auto-update on property
// changes.
//
// This builds indexMap and indexKeys, the data structures used to
// respond to UITableDataSource protocol requests.  UITable expects
// a list of section names, and then ask for items given a section
// index and item index within that section.  In addition, we need
// to do reverse mapping from item to table location.
//
// To facilitate both of these, we build an array of section titles,
// and a dictionary mapping title -> item array.  We could consider
// building a reverse-lookup map too, but this seems unnecessary.
- (void)update
{
  NSInteger objectsShown = 0;
  NSMutableDictionary *indexMap = [[NSMutableDictionary alloc] init];
  NSMutableArray *indexKeys = [[NSMutableArray alloc] init];
  
  for (FBGraphObject *item in self.data) {
    if (![self filterIncludesItem:item]) {
      continue;
    }
    
    NSString *key = [self indexKeyOfItem:item];
    NSMutableArray *existingSection = [indexMap objectForKey:key];
    NSMutableArray *section = existingSection;
    
    if (!section) {
      section = [[NSMutableArray alloc] init];
    }
    [section addObject:item];
    
    if (!existingSection) {
      [indexMap setValue:section forKey:key];
      [indexKeys addObject:key];
    }
    objectsShown++;
  }
  
  if (self.sortDescriptors) {
    for (NSString *key in indexKeys) {
      [[indexMap objectForKey:key] sortUsingDescriptors:self.sortDescriptors];
    }
  }
  if (!self.useCollation) {
    [indexKeys sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
  }
  
  if (self.storedFriendList.count) {
    NSString *key = indexKeyOfRecentUsedContacts;
    NSMutableArray *sectionItems = [NSMutableArray array];
    NSArray *storedItems = [self.storedFriendList valueForKey:@"fbFriend"];
    for (id item in storedItems) {
      if ([item isKindOfClass:[NSDictionary class]]) { // convert saved NSDictionary back to FBGraphObject
        FBGraphObject *restoredItem = (FBGraphObject *)[FBGraphObject graphObjectWrappingDictionary:item];
        if (![self filterIncludesItem:restoredItem]) {
          continue;
        }
        [sectionItems addObject:[FBGraphObject graphObjectWrappingDictionary:restoredItem]];
        
      }
    }
    
    if (sectionItems.count) {
      NSRange limits;
      limits.location = 0;
      limits.length = kMaximumCountOfListedRecentFriends;
      [indexMap setValue:(sectionItems.count > kMaximumCountOfListedRecentFriends)?[sectionItems subarrayWithRange:limits]:sectionItems
                  forKey:key];
      [indexKeys insertObject:key atIndex:0];
    }
  }
  
  self.showSections = objectsShown >= kMinimumCountToCollate;
  self.indexKeys = indexKeys;
  self.indexMap = indexMap;
}

- (void)addItemIntoData:(FBGraphObject *)item
{
  if (![self.data containsObject:item]) {
    NSMutableArray *newData = [self.data mutableCopy];
    [newData addObject:item];
    self.data = newData;
  }
}

- (void)popItemFromData
{
  if (self.data.count) {
    NSMutableArray *newData = [self.data mutableCopy];
    [newData removeObjectAtIndex:self.data.count-1];
    self.data = newData;
  }
}

- (NSString *)nameOfLastItem
{
  if (self.data.count) {
    id<FBGraphUser> item = (id<FBGraphUser>)self.data[self.data.count-1];
    return item.name;
  }
  
  return @"";
}

- (FBGraphObject *)lastObject
{
  if (self.data.count) {
    return self.data[self.data.count-1];
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

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  WAFBGraphObjectTableCell *cell = [self cellWithTableView:tableView];
  
  if ([self isActivityIndicatorIndexPath:indexPath]) {
    cell.picture = nil;
    cell.subtitle = nil;
    cell.title = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selected = NO;
    
    [cell startAnimatingActivityIndicator];
    
    [self.dataNeededDelegate graphObjectTableDataSourceNeedsData:self
                                            triggeredByIndexPath:indexPath];
  } else {
    FBGraphObject *item = [self itemAtIndexPath:indexPath];
    static UIImageView *checkmark;
    checkmark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checked"]];
    NSString *name = [item objectForKey:@"name"];
    
    // This is a no-op if it doesn't have an activity indicator.
    [cell stopAnimatingActivityIndicator];
    
    if (item) {
      if (self.itemPicturesEnabled) {
        if ([self NSStringIsValidEmail:name]) {
          cell.picture = self.defaultPicture;
        } else {
          cell.picture = [self tableView:tableView imageForItem:item];
        }
      } else {
        cell.picture = nil;
      }
      
      if (self.itemTitleSuffixEnabled) {
        cell.titleSuffix = [self.controllerDelegate graphObjectTableDataSource:self
                                                             titleSuffixOfItem:item];
      } else {
        cell.titleSuffix = nil;
      }
      
      if (self.itemSubtitleEnabled) {
        cell.subtitle = [self.controllerDelegate graphObjectTableDataSource:self
                                                             subtitleOfItem:item];
      } else {
        cell.subtitle = nil;
      }
      
      cell.title = [self.controllerDelegate graphObjectTableDataSource:self
                                                           titleOfItem:item];
      
      cell.accessoryView.hidden = YES;
      if ([self.selectionDelegate graphObjectTableDataSource:self
                                       selectionIncludesItem:item]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.accessoryView = checkmark;
        cell.accessoryView.hidden = NO;
        cell.selected = YES;
      } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selected = NO;
      }
      
      if ([self.controllerDelegate respondsToSelector:@selector(graphObjectTableDataSource:customizeTableCell:)]) {
        [self.controllerDelegate graphObjectTableDataSource:self
                                         customizeTableCell:cell];
      }
    } else {
      cell.picture = nil;
      cell.subtitle = nil;
      cell.title = nil;
      cell.accessoryType = UITableViewCellAccessoryNone;
      cell.selected = NO;
    }
  }
  
  return cell;
}

- (NSIndexPath *)indexPathForLastItem
{
  if (self.data.count) {
    return [self indexPathForItem:self.data[self.data.count-1]];
  }
  return nil;
}

- (NSIndexPath *)indexPathForItem:(FBGraphObject *)item
{
  NSString *key = [self indexKeyOfItem:item];
  NSMutableArray *sectionItems = [self.indexMap objectForKey:key];
  if (!sectionItems) {
    return nil;
  }
  
  NSInteger sectionIndex = 0;
  if (self.useCollation) {
    if (self.storedFriendList.count) {
      sectionIndex = [self.collation.sectionTitles indexOfObject:key] + 1;
    } else {
      sectionIndex = [self.collation.sectionTitles indexOfObject:key];
    }
  } else {
    sectionIndex = [self.indexKeys indexOfObject:key];
  }
  if (sectionIndex == NSNotFound) {
    return nil;
  }
  
  id matchingObject = [FBUtility graphObjectInArray:sectionItems withSameIDAs:item];
  if (matchingObject == nil) {
    return nil;
  }
  
  NSInteger itemIndex = [sectionItems indexOfObject:matchingObject];
  if (itemIndex == NSNotFound) {
    return nil;
  }
  
  return [NSIndexPath indexPathForRow:itemIndex inSection:sectionIndex];
}

- (BOOL)isLastSection:(NSInteger)section {
  if (self.useCollation) {
    if (self.storedFriendList.count) {
      return section == self.collation.sectionTitles.count;
    } else {
      return section == self.collation.sectionTitles.count - 1;
    }
  } else {
    return section == self.indexKeys.count - 1;
  }
}

- (FBGraphObject *)itemAtIndexPath:(NSIndexPath *)indexPath
{
  id key = nil;
  if (self.useCollation) {
    if (self.storedFriendList) {
      if (self.storedFriendList.count && !indexPath.section) {
        key = indexKeyOfRecentUsedContacts;
      } else {
        NSString *sectionTitle = [self.collation.sectionTitles objectAtIndex:indexPath.section-1];
        key = sectionTitle;
      }
    } else {
      NSString *sectionTitle = [self.collation.sectionTitles objectAtIndex:indexPath.section];
      key = sectionTitle;
    }
  } else if (indexPath.section >= 0 && indexPath.section < self.indexKeys.count) {
    key = [self.indexKeys objectAtIndex:indexPath.section];
  }
  NSArray *sectionItems = [self.indexMap objectForKey:key];
  if (indexPath.row >= 0 && indexPath.row < sectionItems.count) {
    return [sectionItems objectAtIndex:indexPath.row];
  }
  return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  if (self.useCollation) {
    if (self.storedFriendList.count) {
      return self.collation.sectionTitles.count + 1;
    } else {
      return self.collation.sectionTitles.count;
    }
    
  } else {
    return [self.indexKeys count];
  }
}

- (NSString *)titleForSection:(NSInteger)sectionIndex
{
  id key;
  if (self.useCollation) {
    if (self.storedFriendList) {
      if (self.storedFriendList.count && !sectionIndex) {
        key = NSLocalizedString(@"TITLE_OF_RECENT_USED_CONTACTS", @"Title of recent used contacts or fb friends");
      } else {
        NSString *sectionTitle = [self.collation.sectionTitles objectAtIndex:sectionIndex-1];
        key = sectionTitle;
      }
    } else {
      NSString *sectionTitle = [self.collation.sectionTitles objectAtIndex:sectionIndex];
      key = sectionTitle;
    }
  } else {
    key = [self.indexKeys objectAtIndex:sectionIndex];
  }
  return key;
}

- (NSArray *)sectionItemsForSection:(NSInteger)sectionIndex
{
  NSArray *sectionItems;
  
  if (self.storedFriendList.count && !sectionIndex) {
    sectionItems = [self.indexMap objectForKey:indexKeyOfRecentUsedContacts];
    
  } else {
    id key = [self titleForSection:sectionIndex];
    sectionItems = [self.indexMap objectForKey:key];
    
  }
  
  return sectionItems;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
  //FIXME: crash when title is '#' and index is 27
  if (self.useCollation) {
    return [self.collation sectionForSectionIndexTitleAtIndex:index];
  } else {
    return index;
  }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
  if (self.storedFriendList.count) {
    NSMutableArray *indexTitles = [self.collation.sectionIndexTitles mutableCopy];
    [indexTitles insertObject:indexKeyOfRecentUsedContacts atIndex:0];
    return indexTitles;
    
  } else {
    return self.collation.sectionIndexTitles;
    
  }
}

@end
