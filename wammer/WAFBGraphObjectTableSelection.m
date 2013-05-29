//
//  WAFBGraphObjectTableSelection.m
//  wammer
//
//  Created by Greener Chen on 13/5/16.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAFBGraphObjectTableSelection.h"
#import "WAFBGraphObjectTableDataSource.h"
#import <FBUtility.h>
#import "WAPartioTableViewSectionHeaderView.h"

@interface WAFBGraphObjectTableSelection()

@property (nonatomic, retain) WAFBGraphObjectTableDataSource *dataSource;
@property (nonatomic, strong) UITapGestureRecognizer *tapGuesture;

- (void)selectItem:(FBGraphObject *)item
              cell:(UITableViewCell *)cell;
- (void)  deselectItem:(FBGraphObject *)item
                  cell:(UITableViewCell *)cell
 raiseSelectionChanged:(BOOL) raiseSelectionChanged;
- (void)selectionChanged;

@end

static NSString *kHeaderID = @"WAFBTableViewSectionHeaderView";
static NSString *indexKeyOfRecentUsedContacts = @"★";

@implementation WAFBGraphObjectTableSelection

- (id)initWithDataSource:(WAFBGraphObjectTableDataSource *)dataSource
{
  self = [super init];
  
  if (self) {
    dataSource.selectionDelegate = self;
    
    self.dataSource = dataSource;
    self.allowsMultipleSelection = YES;
    
    NSArray *selection = [[NSArray alloc] init];
    self.selection = selection;
    
  }
  
  return self;
}

- (void)selectItem:(FBGraphObject *)item
{
  if ([FBUtility graphObjectInArray:self.selection withSameIDAs:item] == nil) {
    NSMutableArray *selection = [[NSMutableArray alloc] initWithArray:self.selection];
    [selection addObject:item];
    self.selection = selection;
    
  }
  [self selectionChanged];
}

- (void)selectItem:(FBGraphObject *)item cell:(UITableViewCell *)cell
{
  if ([FBUtility graphObjectInArray:self.selection withSameIDAs:item] == nil) {
    NSMutableArray *selection = [[NSMutableArray alloc] initWithArray:self.selection];
    [selection addObject:item];
    self.selection = selection;
   
  }
  cell.accessoryType = UITableViewCellAccessoryCheckmark;
  static UIImageView *checkmark;
  checkmark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checked"]];
  cell.accessoryView = checkmark;
  cell.accessoryView.hidden = NO;
  [self selectionChanged];
}

- (void)    deselectItem:(FBGraphObject *)item
                    cell:(UITableViewCell *)cell
   raiseSelectionChanged:(BOOL) raiseSelectionChanged
{
  id<FBGraphObject> selectedItem = [FBUtility graphObjectInArray:self.selection withSameIDAs:item];
  if (selectedItem) {
    NSMutableArray *selection = [[NSMutableArray alloc] initWithArray:self.selection];
    [selection removeObject:selectedItem];
    self.selection = selection;
  }
  cell.accessoryView.hidden = YES;
  cell.accessoryType = UITableViewCellAccessoryNone;
  if (raiseSelectionChanged) {
    [self selectionChanged];
  }
}

// Note this method does NOT automatically "raise" the selectionChanged event.
- (void)deselectItems:(NSArray*)items tableView:(UITableView*)tableView
{
  // Copy this so it doesn't change from under us.
  items = [NSArray arrayWithArray:items];
  
  for (FBGraphObject *item in items) {
    NSIndexPath *indexPath = [self.dataSource indexPathForItem:item];
    
    UITableViewCell *cell = nil;
    if (indexPath != nil) {
      cell = [tableView cellForRowAtIndexPath:indexPath];
    }
    
    [self deselectItem:item cell:cell raiseSelectionChanged:NO];
  }
}

- (BOOL)selectionIncludesItem:(id<FBGraphObject>)item
{
  return [FBUtility graphObjectInArray:self.selection withSameIDAs:item] != nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  // cell may be nil, which is okay, it will pick up the right selected state when it is created.
  
  FBGraphObject *item = [self.dataSource itemAtIndexPath:indexPath];
  if (item != nil) {
    // We want to support multi-select on iOS <5.0, so rather than rely on the table view's notion
    // of selection, just treat this as a toggle. If it is already selected, deselect it, and vice versa.
    if (![self selectionIncludesItem:item]) {
      if (self.allowsMultipleSelection == NO) {
        // No multi-select allowed, deselect what is already selected.
        [self deselectItems:self.selection tableView:tableView];
      }
      [self selectItem:item cell:cell];
    } else {
      [self deselectItem:item cell:cell raiseSelectionChanged:YES];
    }
  }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  
  FBGraphObject *item = [self.dataSource itemAtIndexPath:indexPath];

  if (self.allowsMultipleSelection == NO) {
    // Only deselect if we are not allowing multi select. Otherwise, the user will manually
    // deselect this item by clicking on it again.
    
    // cell may be nil, which is okay, it will pick up the right selected state when it is created.
    [self deselectItem:item cell:cell raiseSelectionChanged:NO];
  } else {
    [self deselectItem:item cell:cell raiseSelectionChanged:YES];
  }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  static WAPartioTableViewSectionHeaderView *headerView;
  headerView = [[WAPartioTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0.f, 2.f, CGRectGetWidth(tableView.frame), 22.f)];
  headerView.backgroundColor = tableView.backgroundColor;
  headerView.title.text = [self.dataSource titleForSection:section];
  return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  NSArray *storedFriendList = [[NSUserDefaults standardUserDefaults] arrayForKey:kFrequentFriendList];
  UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
 
  if (storedFriendList.count) {
    if (!section) {
      if ([[self.dataSource.indexMap valueForKey:indexKeyOfRecentUsedContacts] count]) {
        return 22.f;
      }
    
    } else if ([[self.dataSource.indexMap valueForKey:collation.sectionTitles[section-1]] count]) {
      return 22.f;
    }
    
  } else {
    if ([[self.dataSource.indexMap valueForKey:collation.sectionTitles[section]] count]) {
      return 22.f;
    }
  }
  
  return 0.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
  UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, CGRectGetWidth(tableView.frame), 44.f)];
  [footerView setBackgroundColor:[UIColor clearColor]];
  return footerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
  if (section == [tableView numberOfSections] - 1) {
    return 44.f;
  } else {
    return 0.f;
  }
}

@end
