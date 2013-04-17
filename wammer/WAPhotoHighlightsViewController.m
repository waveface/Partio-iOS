//
//  WAPhotoGroupsViewController.m
//  wammer
//
//  Created by Shen Steven on 4/4/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPhotoHighlightsViewController.h"
#import "WAPhotoHighlightViewCell.h"
#import "WADayPhotoPickerViewController.h"
#import "WAPartioNavigationController.h"
#import "WAAssetsLibraryManager.h"
#import "WAOverlayBezel.h"
#import "WAGeoLocation.h"
#import <StackBluriOS/UIImage+StackBlur.h>
#import "WAPhotoTimelineViewController.h"
#import "FBRequestConnection+WAAdditions.h"
#import "WADataStore.h"
#import "WACheckin.h"
#import "WADataStore+FetchingConveniences.h"
#import "WANavigationController.h"
#import <BlocksKit/BlocksKit.h>

#define GROUPING_THRESHOLD (30 * 60)

@interface WAPhotoHighlightsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *allTimeSortedAssets;
@property (nonatomic, strong) NSArray *photoGroups;
@property (nonatomic, strong) FBRequestConnection *fbConnection;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, weak) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation WAPhotoHighlightsViewController

+ (id) viewControllerWithNavigationControllerWrapped {
  
  WAPhotoHighlightsViewController *vc = [[WAPhotoHighlightsViewController alloc] init];
  WAPartioNavigationController *navigationController = [[WAPartioNavigationController alloc] initWithRootViewController:vc];
  navigationController.navigationBarHidden = YES;
  navigationController.toolbarHidden = YES;
  return navigationController;
  
}

- (id) init {
  
  self = [self initWithNibName:nil bundle:nil];
  if (self) {
    
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.allTimeSortedAssets = @[];
  self.photoGroups = [@[] mutableCopy];
  
  if (self.navigationController) {
    __weak WAPhotoHighlightsViewController *wSelf = self;
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"LABEL_ALL_PHOTOS_BUTTON", @"label text of all photos button in highlight") style:UIBarButtonItemStyleBordered handler:^(id sender) {
      WADayPhotoPickerViewController *picker = [[WADayPhotoPickerViewController alloc] initWithSelectedAssets:nil];
      [wSelf.navigationController pushViewController:picker animated:YES];
    }];
    
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ACTION_CANCEL", @"Cancel action") style:UIBarButtonItemStyleBordered handler:^(id sender) {
      [wSelf dismissViewControllerAnimated:YES completion:nil];
    }];
    self.navigationItem.leftBarButtonItem = cancelItem;
    self.navigationItem.rightBarButtonItem = buttonItem;
  }

  self.navigationItem.title = NSLocalizedString(@"TITLE_HIGHLIGHT", @"title of highlights");
  [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
  
  self.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
  
  [self.tableView registerNib:[UINib nibWithNibName:@"WAPhotoHighlightViewCell" bundle:nil] forCellReuseIdentifier:@"WAPhotoHighlightViewCell"];
  
  UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(20, -88, 280, 88)];
  description.textAlignment = NSTextAlignmentCenter;
  description.text = NSLocalizedString(@"HIGHLIGHT_DESCRIPTION", @"description of what is highlight");
  description.textColor = [UIColor whiteColor];
  description.backgroundColor = [UIColor clearColor];
  description.lineBreakMode = NSLineBreakByWordWrapping;
  description.numberOfLines = 0;
  [self.tableView addSubview:description];

  __weak WAPhotoHighlightsViewController *wSelf = self;
  WAOverlayBezel *busyBezel = [[WAOverlayBezel alloc] initWithStyle:WAActivityIndicatorBezelStyle];
  [busyBezel show];
  
  [[WAAssetsLibraryManager defaultManager] retrieveTimeSortedPhotosWhenComplete:^(NSArray *result) {
    wSelf.allTimeSortedAssets = result;
    [busyBezel dismiss];
    
    [wSelf.tableView reloadData];
  } onFailure:^(NSError *error) {
    [busyBezel dismiss];
    
    NSLog(@"error: %@", error);
  }];
  
  if ([FBSession activeSession].isOpen) {
    self.fbConnection = [FBRequestConnection
                         startForUserCheckinsAfterId:nil
                         
                         completeHandler:^(FBRequestConnection *connection, NSArray *result, NSError *error) {
    
                           if (error) {
                             NSLog(@"fb request error: %@", error);
                           } else {
                             //                                                          NSLog(@"fb request success: %@", result);
                             
                             NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
                             NSMutableArray *changedIndexPaths = [NSMutableArray array];
                             
                             for (NSDictionary *checkinItem in result) {
                               NSNumber *timestampNumber = checkinItem[@"timestamp"];
                               NSDate *checkinDate = [NSDate dateWithTimeIntervalSince1970:timestampNumber.floatValue];
                               
                               BOOL found = NO;
                               
                               [WACheckin insertOrUpdateObjectsUsingContext:context withRemoteResponse:result usingMapping:nil options:IRManagedObjectOptionIndividualOperations];
                               
                               NSUInteger groupIndex = 0;
                               for (NSArray *group in self.photoGroups) {
                                 NSDate *enddingDate = [NSDate dateWithTimeInterval:(30*60) sinceDate:[(ALAsset*)group[0] valueForProperty:ALAssetPropertyDate]];
                                 NSDate *beginningDate = [NSDate dateWithTimeInterval:(-30*60) sinceDate:[(ALAsset*)group.lastObject valueForProperty:ALAssetPropertyDate]];
                                 
                                 if (groupIndex == 0) {
                                   NSLog(@"%@ ~ %@", beginningDate, enddingDate);
                                 }
                                 if ([checkinDate compare:beginningDate] == NSOrderedAscending) {
                                   groupIndex ++;
                                   continue;
                                 }
                                 
                                 if ([checkinDate compare:enddingDate] == NSOrderedAscending) {
                                   found = YES;
                                 }
                                 
                                 break;
                                 
                               }
                               
                               if (found) {
                                 NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:groupIndex inSection:0];
                                 if (![changedIndexPaths containsObject:newIndexPath])
                                   [changedIndexPaths addObject:newIndexPath];
                                 NSLog(@"found %@ at indexPath row: %d", checkinItem[@"name"],groupIndex);
                               }
                             }
                             
                             NSError *error = nil;
                             [context save:&error];
                             if (error) {
                               NSLog(@"fail to save checkin for %@", error);
                             }
                             
                             if (changedIndexPaths.count) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                 [wSelf.tableView reloadRowsAtIndexPaths:changedIndexPaths withRowAnimation:YES];
                               });
                             }
                           }
                         }];
    
  }
}


- (NSArray*) photoGroups {
  
  if (_photoGroups.count > 0)
    return _photoGroups;
  
  if (_allTimeSortedAssets.count == 0)
    return @[];
  
  NSMutableArray *sortedGroups = [NSMutableArray array];
  NSMutableArray *photoList = [NSMutableArray array];
  __block NSDate *previousDate = nil;
  
  [_allTimeSortedAssets enumerateObjectsUsingBlock:^(ALAsset *asset, NSUInteger idx, BOOL *stop) {
  
    NSString *filename = [[asset defaultRepresentation] filename];
    NSRange found = [filename rangeOfString:@".PNG" options:NSCaseInsensitiveSearch];
    if (found.location != NSNotFound)
      return;
    
    if (!previousDate) {
      [photoList addObject:asset];
      previousDate = [asset valueForProperty:ALAssetPropertyDate];
      
    } else {
      
      NSDate *assetDate = [asset valueForProperty:ALAssetPropertyDate];
      NSTimeInterval assetInterval = [assetDate timeIntervalSince1970];
      NSTimeInterval previousInterval = [previousDate timeIntervalSince1970];
      if ((previousInterval - assetInterval) > GROUPING_THRESHOLD) {
        
        previousDate = assetDate;
        if (photoList.count > 5)
          [sortedGroups addObject:[photoList copy]];
        
        [photoList removeAllObjects];
        [photoList addObject:asset];
        
      } else {
        
        previousDate = assetDate;
        [photoList addObject:asset];
        
      }
    }
    
  }];
  
  _photoGroups = [NSArray arrayWithArray:sortedGroups];
  return _photoGroups;
}

- (BOOL) shouldAutorotate {
  return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
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
  return [self.photoGroups count];
}

+ (NSOperationQueue*)sharedImageDisplayingQueue {
  
  static NSOperationQueue *opQueue = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    opQueue = [[NSOperationQueue alloc] init];
    opQueue.maxConcurrentOperationCount = 1;
  });
  
  return  opQueue;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"WAPhotoHighlightViewCell";
  WAPhotoHighlightViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
  
  NSArray *photoList = self.photoGroups[indexPath.row];
  ALAsset *asset = photoList[(NSInteger)(photoList.count/2)];
  NSDictionary *imageMeta = [[asset defaultRepresentation] metadata];
  NSDate *eventDate = [asset valueForProperty:ALAssetPropertyDate];
  NSDate *beginDate = [NSDate dateWithTimeInterval:(-30*60) sinceDate:[(ALAsset*)([(NSArray*)(self.photoGroups[indexPath.row]) lastObject]) valueForProperty:ALAssetPropertyDate]];
  NSDate *endDate = [NSDate dateWithTimeInterval:(30*60) sinceDate:[(ALAsset*)(self.photoGroups[indexPath.row][0]) valueForProperty:ALAssetPropertyDate]];


  cell.bgImageView.image = nil;

  NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
    UIImage *image = [[UIImage imageWithCGImage:[asset thumbnail]] stackBlur:1];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [(UIImageView*)cell.bgImageView setImage:image];
    }];
  }];
  [[[self class] sharedImageDisplayingQueue] addOperation:op];
  
  cell.photoNumberLabel.text = [NSString stringWithFormat:@"%d Photos", photoList.count];
  
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter = [[NSDateFormatter alloc] init];
  formatter.dateStyle = NSDateFormatterMediumStyle;
  formatter.timeStyle = NSDateFormatterNoStyle;
  cell.dateLabel.text = [formatter stringFromDate:eventDate];
  
  cell.locationLabel.text = @"";
  
  
  NSFetchRequest * fetchRequest = [[WADataStore defaultStore] newFetchReuqestForCheckinFrom:beginDate to:endDate];

  NSError *error = nil;
  NSArray *checkins = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
  if (error) {
    NSLog(@"error to query checkin db: %@", error);
  } else if (checkins.count) {
    cell.locationLabel.text = [[checkins valueForKeyPath:@"name"] componentsJoinedByString:@","];
  }
  
  if (imageMeta) {
    NSDictionary *gps = imageMeta[@"{GPS}"];
    if (gps) {
      CLLocationCoordinate2D coordinate;
      coordinate.latitude = [(NSNumber*)gps[@"Latitude"] doubleValue];
      coordinate.longitude = [(NSNumber*)gps[@"Longitude"] doubleValue];
      if (cell.geoLocation)
        [cell.geoLocation cancel];
      cell.geoLocation = [[WAGeoLocation alloc] init];
      [cell.geoLocation identifyLocation:coordinate
                              onComplete:^(NSArray *results) {
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                  
                                  if (cell.locationLabel.text.length)
                                    cell.locationLabel.text = [NSString stringWithFormat:@"%@,%@", cell.locationLabel.text, [results componentsJoinedByString:@","]];
                                  else
                                    cell.locationLabel.text = [results componentsJoinedByString:@","];
                                    
                                });
                                
                              } onError:^(NSError *error) {
                                
                                NSLog(@"geolocation error: %@", error);
                                
                              }];
    }
  }

  __weak WAPhotoHighlightsViewController *wSelf = self;
  [cell.addButton removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
  [cell.addButton addEventHandler:^(id sender) {
    WADayPhotoPickerViewController *picker = [[WADayPhotoPickerViewController alloc] initWithSelectedAssets:wSelf.photoGroups[indexPath.row]];
    [wSelf.navigationController pushViewController:picker animated:YES];
  } forControlEvents:UIControlEventTouchUpInside];
  
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  
//  self.navigationController.navigationBarHidden = YES;
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  WAPhotoTimelineViewController *vc = [[WAPhotoTimelineViewController alloc] initWithAssets:self.photoGroups[indexPath.row]];

  [self.navigationController pushViewController:vc animated:YES];
  
}

@end
