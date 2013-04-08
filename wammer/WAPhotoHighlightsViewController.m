//
//  WAPhotoGroupsViewController.m
//  wammer
//
//  Created by Shen Steven on 4/4/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPhotoHighlightsViewController.h"
#import "WAPhotoHighlightViewCell.h"
#import "WAAssetsLibraryManager.h"
#import "WAOverlayBezel.h"
#import "WAGeoLocation.h"
#import <StackBluriOS/UIImage+StackBlur.h>
#import "WAPhotoTimelineViewController.h"
#import "FBRequestConnection+WAAdditions.h"
#import "WADataStore.h"
#import "WACheckin.h"
#import <MagicalRecord/MagicalRecord.h>

#define GROUPING_THRESHOLD (30 * 60)

@interface WAPhotoHighlightsViewController ()

@property (nonatomic, strong) NSArray *allTimeSortedAssets;
@property (nonatomic, strong) NSArray *photoGroups;
@property (nonatomic, strong) FBRequestConnection *fbConnection;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation WAPhotoHighlightsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if (self) {
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.allTimeSortedAssets = @[];
  self.photoGroups = [@[] mutableCopy];
  
  self.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
  
  [self.tableView registerNib:[UINib nibWithNibName:@"WAPhotoGroupViewCell" bundle:nil] forCellReuseIdentifier:@"WAPhotoGroupViewCell"];
  
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
  
  self.fbConnection = [FBRequestConnection startForUserCheckinsAfterId:nil
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
                                                              [changedIndexPaths addObject:[NSIndexPath indexPathForRow:groupIndex inSection:0]];
                                                              NSLog(@"found %@ at indexPath row: %d", checkinItem[@"name"],groupIndex);
                                                            } 
                                                          }
                                                          
                                                          NSError *error = nil;
                                                          [context save:&error];
                                                          if (error) {
                                                            NSLog(@"fail to save checkin for %@", error);
                                                          }
                                                          
                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                            [wSelf.tableView reloadRowsAtIndexPaths:changedIndexPaths withRowAnimation:YES];
                                                          });
                                                        }
                                                      }];

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
  
    if (!previousDate) {
      [photoList addObject:asset];
      previousDate = [asset valueForProperty:ALAssetPropertyDate];
      
    } else {
      
      NSDate *assetDate = [asset valueForProperty:ALAssetPropertyDate];
      NSTimeInterval assetInterval = [assetDate timeIntervalSince1970];
      NSTimeInterval previousInterval = [previousDate timeIntervalSince1970];
      if ((previousInterval - assetInterval) > GROUPING_THRESHOLD) {
        
        previousDate = assetDate;
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
  static NSString *CellIdentifier = @"WAPhotoGroupViewCell";
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
  formatter.timeStyle = NSDateFormatterMediumStyle;
  cell.dateLabel.text = [formatter stringFromDate:eventDate];
  
  cell.locationLabel.text = @"";
  
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"WACheckin"];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"createDate >= %@ AND createDate <= %@", beginDate, endDate];
  [fetchRequest setPredicate:predicate];
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createDate" ascending:NO];
  [fetchRequest setSortDescriptors:@[sortDescriptor]];

  NSError *error = nil;
  NSArray *checkins = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
  if (error) {
    NSLog(@"error to query checkin db: %@", error);
  } else if (checkins.count) {
    cell.locationLabel.text = [[checkins valueForKeyPath:@"name"] componentsJoinedByString:@","];
  } else {
  
    if (imageMeta) {
      NSDictionary *gps = imageMeta[@"{GPS}"];
      if (gps) {
        CLLocationCoordinate2D coordinate;
        coordinate.latitude = [(NSNumber*)gps[@"Latitude"] doubleValue];
        coordinate.longitude = [(NSNumber*)gps[@"Longitude"] doubleValue];
        cell.geoLocation = [[WAGeoLocation alloc] init];
        [cell.geoLocation identifyLocation:coordinate
                                onComplete:^(NSArray *results) {
                              
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                    
                                    cell.locationLabel.text = [NSString stringWithFormat:@"%@%@", cell.locationLabel.text, [results componentsJoinedByString:@","]];
                                    
                                  });
                                  
                                } onError:^(NSError *error) {
                                  
                                  NSLog(@"geolocation error: %@", error);
                                  
                                }];
      }
    }
  }

  
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  
  WAPhotoTimelineViewController *vc = [[WAPhotoTimelineViewController alloc] initWithAssets:self.photoGroups[indexPath.row]];
  
  self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  self.modalPresentationStyle = UIModalPresentationCurrentContext;
  [self presentViewController:vc animated:YES completion:nil];
  
}

@end