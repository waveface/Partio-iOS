//
//  WACollectionPickerViewController.m
//  wammer
//
//  Created by Shen Steven on 3/14/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WACollectionPickerViewController.h"
#import "WADataStore.h"
#import "WACollection.h"
#import "WAAppearance.h"
#import "WAFile+LazyImages.h"
#import "WANavigationController.h"
#import <MagicalRecord/CoreData+MagicalRecord.h>

@interface WACollectionPickerViewController ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, copy) void (^completionBlock)(NSManagedObjectID *selectedCollection);

@end

@implementation WACollectionPickerViewController

+ (id) pickerWithHandler:(void(^)(NSManagedObjectID *selectedCollection))completionBlock onCancel:(void(^)(void))cancelBlock {
  WACollectionPickerViewController *picker = [[WACollectionPickerViewController alloc] initWithHandler:completionBlock];
  WANavigationController *navVC = [[WANavigationController alloc] initWithRootViewController:picker];
  picker.navigationItem.leftBarButtonItem = (UIBarButtonItem*)WABarButtonItem(nil, @"Cancel", ^{
    if (cancelBlock)
      cancelBlock();
  });
  
  return navVC;
}

- (id) initWithHandler:(void(^)(NSManagedObjectID *selectedCollection))completionBlock {

  self = [super initWithStyle:UITableViewStylePlain];
  if (self) {
    self.completionBlock = completionBlock;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    self.managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
    
    NSPredicate *allCollections = [NSPredicate predicateWithFormat:@"isHidden == FALSE"];
    _fetchedResultsController = [WACollection MR_fetchAllSortedBy:@"modificationDate"
                                                        ascending:NO
                                                    withPredicate:allCollections
                                                          groupBy:nil
                                                         delegate:nil
                                                        inContext:self.managedObjectContext];
  
    
  }
  return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.fetchedResultsController fetchedObjects] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
  if(!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  
  WACollection *collection = (WACollection*)self.fetchedResultsController.fetchedObjects[indexPath.row];
  
  cell.imageView.image = nil;
  if(collection.cover) {
    cell.imageView.image = [(WAFile*)collection.cover smallThumbnailImage];
  } else {
    if (collection.files.count > 0) {
      cell.imageView.image = [(WAFile*)collection.files[0] smallThumbnailImage];
    }
  }
  
  cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d)", collection.title, collection.files.count];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  
  return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  
  WACollection *collection = (WACollection*)self.fetchedResultsController.fetchedObjects[indexPath.row];
  if (self.completionBlock) {
    self.completionBlock([collection objectID]);
  }
  
}

@end
