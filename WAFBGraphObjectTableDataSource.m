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

@interface WAFBGraphObjectTableDataSource()

- (WAFBGraphObjectTableCell *)cellWithTableView:(UITableView *)tableView;
- (UIImage *)tableView:(UITableView *)tableView imageForItem:(FBGraphObject *)item;
- (void)addOrRemovePendingConnection:(FBURLConnection *)connection;
- (BOOL)isActivityIndicatorIndexPath:(NSIndexPath *)indexPath;

@end

@implementation WAFBGraphObjectTableDataSource

- (id)init
{
  self = [super init];
  if (self) {
    
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

@end
