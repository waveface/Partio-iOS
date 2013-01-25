//
//  WAUserDetailViewController.m
//  wammer
//
//  Created by Shen Steven on 1/25/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAUserDetailViewController.h"
#import "IRObservings.h"
#import "WADataStore.h"
#import "WAUser.h"

@interface WAUserDetailViewController ()

@property (nonatomic, strong) WAUser *user;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation WAUserDetailViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  __weak WAUserDetailViewController *wSelf = self;
  
  NSKeyValueObservingOptions options = NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew;

  [self irObserveObject:self.user
				keyPath:@"email"
				options:options
				context:nil
			  withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
				
				wSelf.userEmailTableCell.textLabel.text = (NSString *)toValue;
				
			  }];
  
  [self irObserveObject:self.user
				keyPath:@"nickname"
				options:options
				context:nil
			  withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
				
				wSelf.userNameTableCell.textLabel.text = (NSString*)toValue;
				
			  }];

}

- (NSManagedObjectContext *) managedObjectContext {
  
  if (_managedObjectContext)
    return _managedObjectContext;
  
  _managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
  return _managedObjectContext;
  
}

- (WAUser *) user {
  
  if (_user)
    return _user;
  
  _user = [[WADataStore defaultStore] mainUserInContext:self.managedObjectContext];
  return _user;
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) accountDeletionTapped {
  
}

- (NSUInteger) supportedInterfaceOrientations {
  
  if (isPad())
    return UIInterfaceOrientationMaskAll;
  else
    return UIInterfaceOrientationMaskPortrait;
  
}

- (BOOL) shouldAutorotate {
  
  return YES;
  
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  
  UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
  
  return cell;
  
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

  UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
  
  if (selectedCell == self.accountDeleteionTableCell) {
	
	[self accountDeletionTapped];
	
  } else {
	
  }

}

@end
