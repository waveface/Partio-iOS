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
#import "WATimelineIndexView.h"

#import "WAPhotoCollageCell.h"
#import "WADefines.h"

#import "WAAssetsLibraryManager.h"
#import "WAArticle.h"
#import "WADataStore.h"
#import "WAFile.h"
#import "WAFile+LazyImages.h"
#import "WAFileExif.h"
#import "WAFileExif+WAAdditions.h"
#import "WAPeople.h"
#import "WALocation.h"

#import "WADataStore+FetchingConveniences.h"
#import "WAContactPickerViewController.h"
#import "WAGeoLocation.h"
#import <CoreLocation/CoreLocation.h>
#import <GoogleMaps/GoogleMaps.h>
#import <BlocksKit/BlocksKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "WARemoteInterface.h"

@interface WAPhotoTimelineViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>

@property (nonatomic, strong) WAPhotoTimelineCover *headerView;
@property (nonatomic, strong) WAPhotoTimelineNavigationBar *navigationBar;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet WATimelineIndexView *indexView;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSOperationQueue *imageDisplayQueue;

@property (nonatomic, strong) WAArticle *representingArticle;
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
    for (ALAsset *element in enumerator) {
      [array addObject:element];
    }
    self.allAssets = [NSArray arrayWithArray:array];
    
    _coordinate.latitude = 0;
    _coordinate.longitude = 0;
  }
  return self;
}

- (id) initWithArticleID:(NSManagedObjectID *)articleID {
  self = [super initWithNibName:@"WAPhotoTimelineViewController" bundle:nil];
  if (self) {
    
    self.representingArticle = (WAArticle*)[self.managedObjectContext objectWithID:articleID];
    self.allAssets = @[];

  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  naviBarShown = NO;
  
  self.imageDisplayQueue = [[NSOperationQueue alloc] init];
  self.imageDisplayQueue.maxConcurrentOperationCount = 1;
  
  __weak WAPhotoTimelineViewController *wSelf = self;
  self.navigationItem.leftBarButtonItem = WAPartioBackButton(^{
    [wSelf.navigationController popViewControllerAnimated:YES];
  });
  
  if (!self.representingArticle) {
    UIImage *actionImage = [UIImage imageNamed:@"action"];
    UIButton *actionButton = [[UIButton alloc] initWithFrame:(CGRect){CGPointZero, actionImage.size}];
    [actionButton addTarget:self action:@selector(actionButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [actionButton setImage:actionImage forState:UIControlStateNormal];
    UIBarButtonItem *actionItem = [[UIBarButtonItem alloc] initWithCustomView:actionButton];
  
    //  self.navigationItem.leftBarButtonItem = backItem;
    self.navigationItem.rightBarButtonItem = actionItem;
  }
  
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

+ (NSOperationQueue *)sharedImportPhotoOperationQueue {
  
  static NSOperationQueue *opq = nil;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    opq = [[NSOperationQueue alloc] init];
    opq.maxConcurrentOperationCount = 1;
  });
  
  return opq;
}

- (void) finishCreatingSharingEventForSharingTargets:(NSArray *)contacts {
  
  NSDate *importTime = [NSDate date];
  
  NSManagedObjectContext *moc = [[WADataStore defaultStore] autoUpdatingMOC];
  WAArticle *article = [WAArticle objectInsertingIntoContext:moc withRemoteDictionary:@{}];
  
  for (ALAsset *asset in self.allAssets) {
    @autoreleasepool {
      
      NSFetchRequest *fr = [[NSFetchRequest alloc] initWithEntityName:@"WAFile"];
      fr.predicate = [NSPredicate predicateWithFormat:@"assetURL = %@", [[[asset defaultRepresentation] url] absoluteString]];
      NSError *error = nil;
      NSArray *result = [moc executeFetchRequest:fr error:&error];
      if (result.count) {
        
        [[article mutableOrderedSetValueForKey:@"files"] addObject:(WAFile*)result[0]];
        
      } else {
        
        WAFile *file = (WAFile *)[WAFile objectInsertingIntoContext:moc withRemoteDictionary:@{}];
        CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
        if (theUUID)
          file.identifier = [((__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, theUUID)) lowercaseString];
        CFRelease(theUUID);
        file.dirty = (id)kCFBooleanTrue;
        
        [[article mutableOrderedSetValueForKey:@"files"] addObject:file];
        
        UIImage *extraSmallThumbnailImage = [UIImage imageWithCGImage:[asset thumbnail]];
        file.extraSmallThumbnailFilePath = [[[WADataStore defaultStore] persistentFileURLForData:UIImageJPEGRepresentation(extraSmallThumbnailImage, 0.85f) extension:@"jpeg"] path];
        
        file.assetURL = [[[asset defaultRepresentation] url] absoluteString];
        file.resourceType = (NSString *)kUTTypeImage;
        file.timestamp = [asset valueForProperty:ALAssetPropertyDate];
        file.created = file.timestamp;
        file.importTime = importTime;
        
        WAFileExif *exif = (WAFileExif *)[WAFileExif objectInsertingIntoContext:moc withRemoteDictionary:@{}];
        NSDictionary *metadata = [[asset defaultRepresentation] metadata];
        [exif initWithExif:metadata[@"{Exif}"] tiff:metadata[@"{TIFF}"] gps:metadata[@"{GPS}"]];
        
        file.exif = exif;
        
      }
    }
  }
  
  article.event = (id)kCFBooleanTrue;
  article.eventType = [NSNumber numberWithInt:WAEventArticleSharedType];
  article.draft = (id)kCFBooleanFalse;
  CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
  if (theUUID)
    article.identifier = [((__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, theUUID)) lowercaseString];
  CFRelease(theUUID);
  article.dirty = (id)kCFBooleanTrue;
  article.creationDeviceName = [UIDevice currentDevice].name;
  article.eventStartDate = [self beginDate];
  article.eventEndDate = [self endDate];
  article.creationDate = [NSDate date];
  
  NSArray *emailsFromContacts = [contacts valueForKey:@"email"];
  NSMutableArray *invitingEmails = [NSMutableArray array];
  for (NSArray *contactEmails in emailsFromContacts) {
    [invitingEmails addObjectsFromArray:contactEmails];
  }
  NSFetchRequest *fr = [[NSFetchRequest alloc] initWithEntityName:@"WAPeople"];
  fr.predicate = [NSPredicate predicateWithFormat:@"email IN %@", invitingEmails];
  NSError *error = nil;
  NSArray *peopleFound = [moc executeFetchRequest:fr error:&error];
  if (peopleFound.count) {
    for (WAPeople *person in peopleFound) {
      [[article mutableSetValueForKey:@"people"] addObject:person];
      if ([invitingEmails indexOfObject:person.email] != NSNotFound) {
        [invitingEmails removeObject:person.email];
      }
    }
  }
  for (NSString *email in invitingEmails) {
    WAPeople *person = (WAPeople*)[WAPeople objectInsertingIntoContext:moc withRemoteDictionary:@{}];
    person.email = email;
    [[article mutableSetValueForKey:@"people"] addObject:person];
  }
  
  WALocation *location = (WALocation*)[WALocation objectInsertingIntoContext:moc withRemoteDictionary:@{}];
  location.latitude = [NSNumber numberWithFloat:self.coordinate.latitude];
  location.longitude = [NSNumber numberWithFloat:self.coordinate.longitude];
  location.name = @""; // TBD
  article.location = location;
  
  NSError *savingError = nil;
  if ([moc save:&savingError]) {
    NSLog(@"Sharing event successfully created");
  } else {
    NSLog(@"error on creating a new import post for error: %@", savingError);
  }
  
}

- (NSManagedObjectContext*)managedObjectContext {
  
  if (_managedObjectContext)
    return _managedObjectContext;
  
  _managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
  return _managedObjectContext;
  
}

- (NSUInteger) supportedInterfaceOrientations {
  
  return UIInterfaceOrientationMaskPortrait;

}

- (void) backButtonClicked:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)actionButtonClicked:(id)sender
{
  
  __weak WAPhotoTimelineViewController *wSelf = self;
  WAContactPickerViewController *contactPicker = [[WAContactPickerViewController alloc] init];
  if (self.navigationController) {
    
    contactPicker.onNextHandler = ^(NSArray *results) {
      [wSelf finishCreatingSharingEventForSharingTargets:results];
      [wSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
    };
    [self.navigationController pushViewController:contactPicker animated:YES];
    
  }
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CLLocationCoordinate2D)coordinate {
  
  if (_coordinate.latitude!=0 && _coordinate.longitude!=0)
    return _coordinate;

  if (self.representingArticle) {
    _coordinate.latitude = [self.representingArticle.location.latitude floatValue];
    _coordinate.longitude = [self.representingArticle.location.longitude floatValue];
  } else {
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
  }
  return _coordinate;
}

- (NSDate*) eventDate {
  
  if (_eventDate)
    return _eventDate;

  if (self.representingArticle)
    _eventDate = self.representingArticle.eventStartDate;
  else
    _eventDate = [self.allAssets[0] valueForProperty:ALAssetPropertyDate];
  return _eventDate;
  
}

- (NSDate *) beginDate {
  if (_beginDate)
    return _beginDate;
 
  if (self.representingArticle)
    _beginDate = self.representingArticle.eventStartDate;
  else
    _beginDate = [self.allAssets[0] valueForProperty:ALAssetPropertyDate];
  return _beginDate;
}

- (NSDate *) endDate {
  if (_endDate)
    return _endDate;
  
  if (self.representingArticle)
    _endDate = self.representingArticle.eventEndDate;
  else
    _endDate = [self.allAssets.lastObject valueForProperty:ALAssetPropertyDate];
  return _endDate;
}

#pragma mark - UICollectionView datasource
- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return 1;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  
  NSUInteger numOfPhotos = self.allAssets.count;
  if (self.representingArticle)
    numOfPhotos = self.representingArticle.files.count;
  NSUInteger totalItem = (numOfPhotos / 10) * 4;
  NSUInteger mod = numOfPhotos % 10;
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
  
  NSUInteger totalNumber = self.allAssets.count;
  if (self.representingArticle)
    totalNumber = self.representingArticle.files.count;

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
  for (NSUInteger i = 0; i < numOfPhotos; i++) {
    
    if ((base+i) < totalNumber) {
      if (self.representingArticle) {
        
        [self.representingArticle.files[base+i]
         irObserve:@"thumbnailImage"
         options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
         context:nil
         withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
           
           UIImage *image = (UIImage*)toValue;
           [[NSOperationQueue mainQueue] addOperationWithBlock:^{
             ((UIImageView *)cell.imageViews[i]).image = image;
           }];
           
         }];
        
      } else {
        NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
          
          ALAsset *asset = wSelf.allAssets[base+i];
          UIImage *image = [UIImage imageWithCGImage:asset.thumbnail];
          
          [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            ((UIImageView *)cell.imageViews[i]).image = image;
          }];
        }];
        
        [self.imageDisplayQueue addOperation:op];
      }
    } else {
      [(UIImageView*)cell.imageViews[i] setBackgroundColor:[UIColor clearColor]];
    }
  }
  
  return cell;
}

- (UICollectionReusableView*)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
  
  if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        
    WAPhotoTimelineCover *cover = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PhotoTimelineCover" forIndexPath:indexPath];
    
    if (self.representingArticle) {
    
      [self.representingArticle.representingFile
       irObserve:@"thumbnailImage"
       options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
       context:nil
       withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {

         UIImage *image = (UIImage*)toValue;
         [[NSOperationQueue mainQueue] addOperationWithBlock:^{
           cover.coverImageView.image = image;
         }];
         
       }];
      
    } else {
      ALAsset *coverAsset = self.allAssets[(NSInteger)(self.allAssets.count/3)];
      
      NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        
        UIImage *coverImage = [UIImage imageWithCGImage:[coverAsset defaultRepresentation].fullScreenImage];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          cover.coverImageView.image = coverImage;
        }];
      }];

      [self.imageDisplayQueue addOperation:op];
    }
    
    self.headerView = cover;
    
    NSUInteger zoomLevel = 15; // hardcoded, but we may tune this in the future
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:self.coordinate.latitude
                                                            longitude:self.coordinate.longitude
                                                                 zoom:zoomLevel];
    
    [cover.mapView setCamera:camera];
    cover.mapView.myLocationEnabled = NO;
    
    NSFetchRequest * fetchRequest = [[WADataStore defaultStore] newFetchReuqestForCheckinFrom:[self beginDate] to:[self endDate]];
    
    NSError *error = nil;
    NSArray *checkins = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
      NSLog(@"error to query checkin db: %@", error);
    } else if (checkins.count) {
      cover.titleLabel.text = [[checkins valueForKeyPath:@"name"] componentsJoinedByString:@","];
    }
    
    cover.titleLabel.text = @"";
    self.geoLocation = [[WAGeoLocation alloc] init];
    [self.geoLocation identifyLocation:self.coordinate onComplete:^(NSArray *results) {
      if (cover.titleLabel.text.length == 0)
        cover.titleLabel.text = [results componentsJoinedByString:@","];
      else
        cover.titleLabel.text = [NSString stringWithFormat:@"%@,%@", cover.titleLabel.text, [results componentsJoinedByString:@","]];
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
    
  if (scrollView.contentOffset.y > 0) {
//    CGFloat ratio = scrollView.contentSize.height / (scrollView.contentSize.height - scrollView.frame.size.height);
    CGFloat percent = (scrollView.contentOffset.y / (scrollView.contentSize.height - self.collectionView.frame.size.height));
    NSLog(@"%@ %f", NSStringFromCGSize(scrollView.contentSize), percent);
    self.indexView.percentage = percent;
  }

}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  if (!self.indexView.hidden) {
    [UIView animateWithDuration:1 animations:^{
      self.indexView.hidden = YES;
      
    }];
  }
}

@end
