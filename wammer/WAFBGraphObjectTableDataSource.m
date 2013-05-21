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

// Magic number - iPhone address book doesn't show scrubber for less than 5 contacts
static const NSInteger kMinimumCountToCollate = 6;
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
    self.storedFriendList = [[[NSUserDefaults standardUserDefaults] arrayForKey:kFrenquentFriendList] mutableCopy];

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
          if ([recentUsedFBFriends containsObject:item] &&
              (!self.recentFriendImageShown || [self.recentFriendImageShown[[recentUsedFBFriends indexOfObject:item]] isEqual:@NO])) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[recentUsedFBFriends indexOfObject:item] inSection:0];
            WAFBGraphObjectTableCell *cell = (WAFBGraphObjectTableCell*)[tableView cellForRowAtIndexPath:indexPath];
            
            if (cell) {
              cell.picture = image;
              self.recentFriendImageShown[[recentUsedFBFriends indexOfObject:item]] = @YES;
            }
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
        [sectionItems addObject:[FBGraphObject graphObjectWrappingDictionary:item]];
        
      }
    }
    [indexMap setValue:sectionItems forKey:key];
    [indexKeys insertObject:key atIndex:0];
  }
  
  self.showSections = objectsShown >= kMinimumCountToCollate;
  self.indexKeys = indexKeys;
  self.indexMap = indexMap;
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
    
    // This is a no-op if it doesn't have an activity indicator.
    [cell stopAnimatingActivityIndicator];
    if (item) {
      if (self.itemPicturesEnabled) {
        cell.picture = [self tableView:tableView imageForItem:item];
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
      
      static UIImageView *checkmark;
      checkmark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checked"]];
      
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
      sectionIndex = [self.collation.sectionTitles indexOfObject:key] - 1;
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
  if (self.useCollation) {
    if (self.storedFriendList.count) {
      return [self.collation sectionForSectionIndexTitleAtIndex:index] - 1;
    } else {
      return [self.collation sectionForSectionIndexTitleAtIndex:index];
    }
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
