//
//  WAPhotoTimelineViewController.m
//  wammer
//
//  Created by Shen Steven on 4/5/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPhotoTimelineViewController.h"
#import "WAPhotoTimelineNavigationBar.h"
#import "WAPhotoTimelineCover.h"
#import "WAPhotoTimelineLayout.h"
#import "WAPhotoCollageCell.h"
#import "WAAssetsLibraryManager.h"
#import "WATimelineIndexView.h"
#import <CoreLocation/CoreLocation.h>
#import "WAGeoLocation.h"
#import <GoogleMaps/GoogleMaps.h>


@interface WAPhotoTimelineViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>

@property (nonatomic, strong) WAPhotoTimelineCover *headerView;
@property (nonatomic, strong) WAPhotoTimelineNavigationBar *navigationBar;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet WATimelineIndexView *indexView;
@property (nonatomic, strong) NSOperationQueue *imageDisplayQueue;
@property (nonatomic, strong) NSArray *allAssets;
@property (nonatomic, strong) WAGeoLocation *geoLocation;
@property (nonatomic, strong) NSDate *eventDate;
@property (nonatomic, strong) NSDate *beginDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end

@implementation WAPhotoTimelineViewController {
  BOOL naviBarShown;
  CLLocationCoordinate2D _coordinate;
}

- (id) initWithAssets:(NSArray *)assets {
  self = [super initWithNibName:@"WAPhotoTimelineViewController" bundle:nil];
  if (self) {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:assets.count];
    NSEnumerator *enumerator = [assets reverseObjectEnumerator];
    for (id element in enumerator) {
      [array addObject:element];
    }
    self.allAssets = [NSArray arrayWithArray:array];
    _coordinate.latitude = 0;
    _coordinate.longitude = 0;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  naviBarShown = NO;
  
  self.imageDisplayQueue = [[NSOperationQueue alloc] init];
  self.imageDisplayQueue.maxConcurrentOperationCount = 1;
  
  UIImage *backImage = [UIImage imageNamed:@"back"];
  UIButton *backButton = [[UIButton alloc] initWithFrame:(CGRect){CGPointZero, backImage.size}];
  [backButton addTarget:self action:@selector(backButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
  [backButton setImage:backImage forState:UIControlStateNormal];
  UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
  
  UIImage *actionImage = [UIImage imageNamed:@"action"];
  UIButton *actionButton = [[UIButton alloc] initWithFrame:(CGRect){CGPointZero, actionImage.size}];
  [actionButton setImage:actionImage forState:UIControlStateNormal];
  UIBarButtonItem *actionItem = [[UIBarButtonItem alloc] initWithCustomView:actionButton];
  
  self.navigationItem.leftBarButtonItem = backItem;
  self.navigationItem.rightBarButtonItem = actionItem;
  
  self.navigationBar = [[WAPhotoTimelineNavigationBar alloc] initWithFrame:(CGRect)CGRectMake(0, 0, self.view.frame.size.width, 44)];
  self.navigationBar.barStyle = UIBarStyleDefault;
  self.navigationBar.tintColor = [UIColor clearColor];
  self.navigationBar.backgroundColor = [UIColor clearColor];
  self.navigationBar.translucent = YES;
  //  self.navigationBar.items = @[backItem, actionItem];
  [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
  
  [self.view addSubview:self.navigationBar];
  
  [self.collectionView setBackgroundColor:[UIColor blackColor]];
  ((UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout).minimumLineSpacing = 0.0f;
  
  self.collectionView.showsVerticalScrollIndicator = NO;
  
  [self.collectionView registerNib:[UINib nibWithNibName:@"WAPhotoTimelineCover" bundle:nil]
        forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
               withReuseIdentifier:@"PhotoTimelineCover"];
  
  [self.collectionView registerNib:[UINib nibWithNibName:@"WAPhotoCollageCell_Stack4" bundle:nil]
        forCellWithReuseIdentifier:@"CollectionItemCell4"];
  [self.collectionView registerNib:[UINib nibWithNibName:@"WAPhotoCollageCell_Stack3" bundle:nil]
        forCellWithReuseIdentifier:@"CollectionItemCell3"];
  [self.collectionView registerNib:[UINib nibWithNibName:@"WAPhotoCollageCell_Stack2" bundle:nil]
        forCellWithReuseIdentifier:@"CollectionItemCell2"];
  [self.collectionView registerNib:[UINib nibWithNibName:@"WAPhotoCollageCell_Stack1" bundle:nil]
        forCellWithReuseIdentifier:@"CollectionItemCell1"];

  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter = [[NSDateFormatter alloc] init];
  formatter.dateStyle = NSDateFormatterNoStyle;
  formatter.timeStyle = NSDateFormatterShortStyle;

  [self.indexView addIndex:0.01 label:[formatter stringFromDate:self.beginDate]];
  [self.indexView addIndex:0.99 label:[formatter stringFromDate:self.endDate]];
}

- (BOOL) shouldAutorotate {

  return YES;

}

- (NSUInteger) supportedInterfaceOrientations {
  
  return UIInterfaceOrientationMaskPortrait;

}

- (void) backButtonClicked:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CLLocationCoordinate2D)coordinate {
  
  if (_coordinate.latitude!=0 && _coordinate.longitude!=0)
    return _coordinate;
  
  for (ALAsset *asset in self.allAssets) {
    NSDictionary *meta = [asset defaultRepresentation].metadata;
    if (meta) {
      NSDictionary *gps = meta[@"{GPS}"];
      if (gps) {
        _coordinate.latitude = [(NSNumber*)[gps valueForKey:@"Latitude"] doubleValue];
        _coordinate.longitude = [(NSNumber*)[gps valueForKey:@"Longitude"] doubleValue];
        break;
      }
    }
  }
  return _coordinate;
}

- (NSDate*) eventDate {
  
  if (_eventDate)
    return _eventDate;
  
  _eventDate = [self.allAssets[0] valueForProperty:ALAssetPropertyDate];
  return _eventDate;
  
}

- (NSDate *) beginDate {
  if (_beginDate)
    return _beginDate;
  
  _beginDate = [self.allAssets[0] valueForProperty:ALAssetPropertyDate];
  return _beginDate;
}

- (NSDate *) endDate {
  if (_endDate)
    return _endDate;
  
  _endDate = [self.allAssets.lastObject valueForProperty:ALAssetPropertyDate];
  return _endDate;
}

#pragma mark - UICollectionView datasource
- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return 1;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  
  NSUInteger totalItem = (self.allAssets.count / 10) * 4;
  NSUInteger mod = self.allAssets.count % 10;
  if (mod == 0)
    return totalItem;
  else if (mod < 4)
    return totalItem + 1;
  else if (mod < 7)
    return totalItem + 2;
  else if (mod < 9)
    return totalItem + 3;
  else
    return totalItem + 4;
  
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  NSUInteger numOfPhotos = 4 - (indexPath.row % 4);
  NSString *identifier = [NSString stringWithFormat:@"CollectionItemCell%d", numOfPhotos];
  
  WAPhotoCollageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
  
  NSUInteger base = 0;
  switch(indexPath.row % 4) {
    case 3:
      base = (indexPath.row / 4) * 10 + 9;
      break;
    case 2:
      base = (indexPath.row / 4) * 10 + 7;
      break;
    case 1:
      base = (indexPath.row / 4) * 10 + 4;
      break;
    case 0:
      base = (indexPath.row / 4) * 10;
      break;
  }
  
  __weak WAPhotoTimelineViewController *wSelf = self;
  for (NSUInteger i = 0; i < numOfPhotos && ((base+i)<self.allAssets.count); i++) {
    
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
      ALAsset *asset = wSelf.allAssets[base+i];
      UIImage *image = [UIImage imageWithCGImage:[asset thumbnail]];
      
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        ((UIImageView *)cell.imageViews[i]).image = image;
      }];
    }];
    
    [self.imageDisplayQueue addOperation:op];
  }
  
  return cell;
}

- (UICollectionReusableView*)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
  
  if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        
    WAPhotoTimelineCover *cover = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PhotoTimelineCover" forIndexPath:indexPath];
    
    ALAsset *coverAsset = self.allAssets[(NSInteger)(self.allAssets.count/3)];

    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
      UIImage *coverImage = [UIImage imageWithCGImage:[coverAsset defaultRepresentation].fullScreenImage];

      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        cover.coverImageView.image = coverImage;
      }];
    }];
    
    [self.imageDisplayQueue addOperation:op];
    
    self.headerView = cover;
    
    NSUInteger zoomLevel = 15; // hardcoded, but we may tune this in the future
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:self.coordinate.latitude
                                                            longitude:self.coordinate.longitude
                                                                 zoom:zoomLevel];
    
    [cover.mapView setCamera:camera];
    cover.mapView.myLocationEnabled = NO;
    
    self.geoLocation = [[WAGeoLocation alloc] init];
    [self.geoLocation identifyLocation:self.coordinate onComplete:^(NSArray *results) {
      cover.titleLabel.text = [results componentsJoinedByString:@","];
    } onError:^(NSError *error) {
      NSLog(@"Unable to identify location: %@", error);
    }];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterMediumStyle;
    cover.dateLabel.text = [formatter stringFromDate:self.eventDate];
    
    return cover;
    
  }
  return nil;
}

#pragma mark - UICollectionViewFlowLayout delegate

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
  
  return CGSizeMake(self.collectionView.frame.size.width, 250);
  
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  CGFloat height = 200;
  switch (indexPath.row % 4) {
    case 0:
      height = 210;
      break;
    case 1:
      height = 90;
      break;
    case 2:
      height = 130;
      break;
    case 3:
      height = 210;
      break;
  }
  return CGSizeMake(self.collectionView.frame.size.width, height);
  
}

- (void) showingNavigationBar {
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(25, 0, 200, 44)];
  label.text = self.headerView.titleLabel.text;
  label.tag = 99;
  label.textColor = [UIColor colorWithWhite:255 alpha:0.2];
  label.backgroundColor = [UIColor clearColor];
  label.alpha = 0.2f;
  [self.navigationBar addSubview:label];
  
  [UIView animateWithDuration:0.3
                        delay:0
                      options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionShowHideTransitionViews
                   animations:^{
                     
                     label.textColor = [UIColor whiteColor];
                     label.frame = CGRectMake(50, 0, 200, 44);
                     label.alpha = 1.0f;
                   } completion:^(BOOL finished) {
                     
                   }];
  self.navigationBar.solid = YES;
  [self.navigationBar setNeedsDisplay];
  
}

- (void) hideNavigationBar {
  [self.navigationBar.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    if ([obj isKindOfClass:[UILabel class]] && [obj tag] == 99) {
      UILabel *label = (UILabel*)obj;
      
      [UIView animateWithDuration:1
                            delay:0
                          options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionShowHideTransitionViews
                       animations:^{
                         label.textColor = [UIColor colorWithWhite:255 alpha:0.2];
                         label.alpha = 0.0f;
                       } completion:^(BOOL finished) {
                         
                         [label removeFromSuperview];
                         
                       }];
      
    }
  }];
  
  self.navigationBar.solid = NO;
  [self.navigationBar setNeedsDisplay];
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
  
  if (self.indexView.hidden && scrollView.contentOffset.y > 0)
    self.indexView.hidden = NO;
  
  if (!naviBarShown && scrollView.contentOffset.y >= (250-44-50)) {
    
    [self performSelectorOnMainThread:@selector(showingNavigationBar) withObject:nil waitUntilDone:NO modes:@[NSRunLoopCommonModes]];
    naviBarShown = YES;
    
  }
  
  if (naviBarShown && scrollView.contentOffset.y <= (250-44-50)) {
    [self performSelectorOnMainThread:@selector(hideNavigationBar) withObject:nil waitUntilDone:NO modes:@[NSRunLoopCommonModes]];
    naviBarShown = NO;
  }
    
  if (scrollView.contentOffset.y > 0)
    self.indexView.percentage = (scrollView.contentOffset.y / scrollView.contentSize.height);
  
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  if (!self.indexView.hidden) {
    [UIView animateWithDuration:1 animations:^{
      self.indexView.hidden = YES;
      
    }];
  }
}

@end