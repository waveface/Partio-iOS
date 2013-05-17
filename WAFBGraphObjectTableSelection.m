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
@property (nonatomic, retain) NSArray *selection;

- (void)selectItem:(FBGraphObject *)item
              cell:(UITableViewCell *)cell;
- (void)  deselectItem:(FBGraphObject *)item
                  cell:(UITableViewCell *)cell
 raiseSelectionChanged:(BOOL) raiseSelectionChanged;
- (void)selectionChanged;

@end

static NSString *kHeaderID = @"WAFBTableViewSectionHeaderView";

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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  UIView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kHeaderID];
  return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  return 22.f;
}
@end
