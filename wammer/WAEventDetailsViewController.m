//
//  WAEventDetailsViewController.m
//  wammer
//
//  Created by Shen Steven on 4/18/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAEventDetailsViewController.h"
#import "WAPartioTableViewSectionHeaderView.h"
#import "WADataStore.h"
#import "WAArticle.h"
#import "WAEventDetailsMapCell.h"
#import "WACheckin.h"
#import "WAGeoLocation.h"
#import "WAEventDetailsCell.h"
#import "WANavigationController.h"
#import <BlocksKit/BlocksKit.h>
#import <MapKit/MapKit.h>

@interface WACheckinAnnotation : NSObject
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;
@end

@implementation WACheckinAnnotation

@end

@interface WAEventDetailsViewController () <MKMapViewDelegate>
@property (nonatomic, strong) NSDictionary *details;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) NSString *locationName;
@property (nonatomic, strong) WAGeoLocation *geoLocation;
@property (nonatomic, strong) WAEventDetailsMapCell *mapCell;
@end

@implementation WAEventDetailsViewController

+ (id) wrappedNavigationControllerForDetailInfo:(NSDictionary *)detail {
  WAEventDetailsViewController *vc = [[WAEventDetailsViewController alloc] initWithDetailInfo:detail];
  WANavigationController *nav = [[WANavigationController alloc] initWithRootViewController:vc];
  nav.navigationBar.translucent = YES;
  nav.navigationBar.tintColor = [UIColor blackColor];
  vc.title = NSLocalizedString(@"TITLE_EVENT_DETAILS", @"Title of event details");
  vc.navigationItem.leftBarButtonItem = WAPartioNaviBarButton(NSLocalizedString(@"CLOSE_BUTTON", @""), [UIImage imageNamed:@"Btn1"], nil, ^{
    [nav dismissViewControllerAnimated:YES completion:nil];
  });
  
  return nav;
}

- (id) initWithDetailInfo:(NSDictionary *)detail {
  self = [super initWithStyle:UITableViewStylePlain];
  if (self) {
    self.details = detail;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self.tableView registerNib:[UINib nibWithNibName:@"WAEventDetailsMapCell" bundle:nil] forCellReuseIdentifier:@"mapCell"];
  [self.tableView registerNib:[UINib nibWithNibName:@"WAEventDetailsCell" bundle:nil] forCellReuseIdentifier:@"contactCell"];

  UIImage *wmImage = [UIImage imageNamed:@"watermark"];
  UIImageView *waterMark = [[UIImageView alloc] initWithImage:wmImage];
  waterMark.frame = CGRectMake(self.tableView.frame.size.width/2-wmImage.size.width/2, -(wmImage.size.height)-30, wmImage.size.width, wmImage.size.height);
  [self.tableView addSubview:waterMark];
  
  __weak WAEventDetailsViewController *wSelf = self;
  self.geoLocation = [[WAGeoLocation alloc] init];
  [self.geoLocation identifyLocation:self.coordinate
                          onComplete:^(NSArray *results) {
                            wSelf.locationName = [results componentsJoinedByString:@","];
                            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
                            [wSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:YES];
                          } onError:^(NSError *error) {
                            
                          }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CLLocationCoordinate2D)coordinate {
  
  if (_coordinate.latitude!=0 && _coordinate.longitude!=0)
    return _coordinate;
  
  _coordinate.latitude = [self.details[@"latitude"] floatValue];
  _coordinate.longitude = [self.details[@"longitude"] floatValue];
  return _coordinate;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (section == 2)
    return [self.details[@"checkins"] count];
  if (section == 5)
    return [self.details[@"contacts"] count];
  return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  if (section == 0)
    return 0;
  return 22;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  NSString *title = nil;
  if (section == 0) {
    return nil;
  }
  
  if (section == 1)
    title = NSLocalizedString(@"DETAIL_LOCATION", @"Location section header for detail");
  
  if (section == 2)
    title = NSLocalizedString(@"DETAIL_CHECKINS", @"Checkins section header for detail");
  
  if (section == 3)
    title = NSLocalizedString(@"DETAIL_START_TIME", @"Start time section header for detail");
  
  if (section == 4)
    title = NSLocalizedString(@"DETAIL_END_TIME", @"End time section header for detail");
  
  if (section == 5)
    title = NSLocalizedString(@"DETAIL_MEMBERS", @"Member section header for detail");

  static WAPartioTableViewSectionHeaderView *headerView;
  headerView = [[WAPartioTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0.f, 2.f, CGRectGetWidth(tableView.frame), 22.f)];
  headerView.backgroundColor = tableView.backgroundColor;
  headerView.title.text = title;
  headerView.title.font = [UIFont fontWithName:@"OpenSans-Semibold" size:16];
  headerView.title.textAlignment = NSTextAlignmentLeft;
  return headerView;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
  
  static NSString *annotationIdentifier = @"EventMapView-Annotation";
  MKAnnotationView *annView = (MKAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
  if (annView == nil) {
	annView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
  }
  
  annView.canShowCallout = NO;
  annView.draggable = NO;
  annView.image = [UIImage imageNamed:@"pindrop"];
  return annView;
  
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }

  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter = [[NSDateFormatter alloc] init];
  formatter.dateStyle = NSDateFormatterMediumStyle;
  formatter.timeStyle = NSDateFormatterMediumStyle;

  if (indexPath.section == 0) {
    if (!self.mapCell) {
      WAEventDetailsMapCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mapCell" forIndexPath:indexPath];
    
      MKCoordinateRegion region = MKCoordinateRegionMake(self.coordinate, MKCoordinateSpanMake(0.02, 0.02));
      cell.mapView.region = region;
      cell.mapView.delegate = self;
      
      NSMutableArray *pins = [NSMutableArray array];
      for (WACheckin *checkin in self.details[@"checkins"]) {
        WACheckinAnnotation *anno = [[WACheckinAnnotation alloc] init];
        anno.coordinate = CLLocationCoordinate2DMake(checkin.latitude.doubleValue, checkin.longitude.doubleValue);
        [pins addObject:anno];
      }
      if (pins.count)
        [cell.mapView addAnnotations:pins];
      
      self.mapCell = cell;
    }
    return self.mapCell;
  } else if (indexPath.section == 1) {
    cell.textLabel.text = self.locationName;
  } else if (indexPath.section == 3) {
    cell.textLabel.text = [formatter stringFromDate:self.details[@"eventStartDate"]];
  } else if (indexPath.section == 4) {
    cell.textLabel.text = [formatter stringFromDate:self.details[@"eventEndDate"]];
  } else if (indexPath.section == 2) {
    WACheckin *checkin = (WACheckin*)[self.details[@"checkins"] objectAtIndex:indexPath.row];
    cell.textLabel.text = checkin.name;
  } else if (indexPath.section == 5) {
    WAEventDetailsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
    WAPeople *contact = (WAPeople*)[self.details[@"contacts"] objectAtIndex:indexPath.row];
    cell.nameLabel.text = contact.name;
    cell.emailLabel.text = contact.email;
    cell.avatarView.image = [UIImage imageNamed:@"Avatar"];
    if (contact.avatarURL) {
      [cell.avatarView setPathToNetworkImage:contact.avatarURL
                              forDisplaySize:cell.avatarView.frame.size
                                 contentMode:UIViewContentModeScaleAspectFill];
    }
    return cell;
    
  }
  
  cell.textLabel.textColor = [UIColor whiteColor];
  cell.textLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:15];
  
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if (indexPath.section == 0){
    return 180;
  }
  
  return 44;

}


- (BOOL) shouldAutorotate {

  return YES;

}

- (NSUInteger)supportedInterfaceOrientations {

  return UIInterfaceOrientationMaskPortrait;

}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
