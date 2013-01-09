//
//  WAImportSettingsViewController.m
//  wammer
//
//  Created by kchiu on 12/11/27.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAImportSettingsViewController.h"
#import "WADefines.h"
#import "WAFacebookConnectionSwitch.h"
#import "WADataStore.h"
#import "WARemoteInterface.h"

@interface WAImportSettingsViewController ()

@property (nonatomic, strong) UISwitch *photoImportSwitch;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

- (void)handlePhotoImportSwitchChanged:(id)sender;

@end

@implementation WAImportSettingsViewController

- (void)viewDidLoad {
  
  [super viewDidLoad];
  
  self.title = NSLocalizedString(@"PHOTO_IMPORT_TITLE", @"Title of photo import settings view controller");
  
  self.photoImportSwitch = [[UISwitch alloc] init];
  [self.photoImportSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kWAPhotoImportEnabled]];
  [self.photoImportSwitch addTarget:self action:@selector(handlePhotoImportSwitchChanged:) forControlEvents:UIControlEventValueChanged];
  self.photoImportCell.accessoryView = self.photoImportSwitch;
  
  UISwitch *useCellularSwitch = [[UISwitch alloc] init];
  [useCellularSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kWAUseCellularEnabled]];
  [useCellularSwitch addTarget:self action:@selector(handleUseCellularSwitchChanged:) forControlEvents:UIControlEventValueChanged];
  self.useCellularCell.accessoryView = useCellularSwitch;
  
  NSManagedObjectContext *context = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
  request.entity = [NSEntityDescription entityForName:@"WAFile" inManagedObjectContext:context];
  request.predicate = [NSPredicate predicateWithFormat:@"(assetURL != nil OR resourceFilePath != nil) AND resourceURL == nil"];
  request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
  self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
  self.fetchedResultsController.delegate = self;
  
  NSError *error = nil;
  if ([self.fetchedResultsController performFetch:&error]) {
    self.pendingFilesCell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [self.fetchedResultsController.fetchedObjects count]];
  } else {
    NSLog(@"Unable to fetch files needing backup, error:%@", error);
  }
  
}

- (void)didReceiveMemoryWarning {
  
  [super didReceiveMemoryWarning];
  
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

#pragma mark - Target actions

- (void)handlePhotoImportSwitchChanged:(id)sender {
  
  UISwitch *photoImportSwitch = sender;
  if ([photoImportSwitch isOn]) {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWAPhotoImportEnabled];
  } else {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWAPhotoImportEnabled];
  }
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [self.tableView reloadData];
  
}

- (void)handleUseCellularSwitchChanged:(id)sender {

  UISwitch *useCellularSwitch = sender;
  if ([useCellularSwitch isOn]) {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWAUseCellularEnabled];
  } else {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWAUseCellularEnabled];
  }
  [[NSUserDefaults standardUserDefaults] synchronize];

}

#pragma mark - UITableView delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  
  if ([self.photoImportSwitch isOn]) {
    // show settings section
    return 2;
  }
  
  return 1;
  
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  
  NSString *headerTitleID = [super tableView:tableView titleForHeaderInSection:section];
  
  return NSLocalizedString(headerTitleID, @"Header title in photo import settings view controller");
  
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
  
  NSString *footerTitleID = [super tableView:tableView titleForFooterInSection:section];

  if ([footerTitleID isEqualToString:@"PHOTO_IMPORT_SWITCH_FOOTER"]) {
    if ([self.photoImportSwitch isOn]) {
      return nil;
    }
  }

  return NSLocalizedString(footerTitleID, @"Footer title in photo import settings view controller");
  
}

#pragma mark - NSFetchedResultsController delegates

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
  
  NSParameterAssert([NSThread isMainThread]);
  
  self.pendingFilesCell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [controller.fetchedObjects count]];
  
}

@end
