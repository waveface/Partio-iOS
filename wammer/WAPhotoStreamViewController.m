//
//  WAPhotoStreamViewController.m
//  wammer
//
//  Created by jamie on 12/11/6.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAPhotoStreamViewController.h"
#import "CoreData+MagicalRecord.h"
#import "WAFile.h"
#import "WADataStore.h"
#import "WAPhotoStreamViewCell.h"
#import "NSDate+WAAdditions.h"
#import "WADayHeaderView.h"
#import "WAGalleryViewController.h"
#import "WACalendarPickerViewController.h"

@interface WAPhotoStreamViewController (){
  NSArray *colorPalette;
  NSArray *daysOfPhotos;
  NSDate *onDate;
}

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSArray *photos;
@property (strong, nonatomic) NSMutableArray *layout;

@end

@implementation WAPhotoStreamViewController

- (id)initWithDate:(NSDate *)aDate {
  self = [super init];
  if (self) {
    onDate = aDate;
    NSPredicate *allFromToday = [NSPredicate predicateWithFormat:@"created BETWEEN {%@, %@}", [aDate dayBegin], [aDate dayEnd]];
    NSMutableArray *unsortedPhotos = [[WAFile MR_findAllWithPredicate:allFromToday inContext:[[WADataStore defaultStore] defaultAutoUpdatedMOC]] mutableCopy];
    NSSortDescriptor *sortByTime = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    [unsortedPhotos sortUsingDescriptors:@[sortByTime]];
    _photos = unsortedPhotos;
  }
  return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

/* Reflow Layout engine base on Partition (Number Theory)
 http://en.wikipedia.org/wiki/Partition_(number_theory)
 */
- (void)reloadLayout:(NSArray *)partition
{
  NSInteger MAX = [[partition[0] valueForKeyPath:@"@sum.intValue"] integerValue];
  _layout = [@[]mutableCopy];
  NSArray *aLayout;
  int previousLayout=[_photos count]+1;
  for (int i=0; i<[_photos count]; i+=[aLayout count]) {
    int candidateLayout = arc4random_uniform([partition count]);
    if (candidateLayout == previousLayout)
      candidateLayout = (candidateLayout+1) % MAX;
    previousLayout = candidateLayout;
    aLayout=partition[candidateLayout];
    [_layout addObjectsFromArray:aLayout];
  }
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  
  [self.collectionView registerClass:[WAPhotoStreamViewCell class]
          forCellWithReuseIdentifier:kPhotoStreamCellID];
  [self.collectionView registerNib:[UINib nibWithNibName:@"WADayHeaderView" bundle:nil]
        forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
               withReuseIdentifier:@"PhotoStreamHeaderView"];
  
  colorPalette = @[
                   [UIColor colorWithRed:224/255.0 green:96/255.0 blue:76/255.0 alpha:1.0],
                   [UIColor colorWithRed:118/255.0 green:170/255.0 blue:204/255.0 alpha:1.0],
                   [UIColor colorWithRed:1.000 green:0.651 blue:0.000 alpha:1.000],
                   [UIColor colorWithRed:0.486 green:0.612 blue:0.208 alpha:1.000],
                   [UIColor colorWithRed:0.176 green:0.278 blue:0.475 alpha:1.000]
                   ];
  
  self.collectionView.backgroundColor = [UIColor colorWithWhite:0.16f alpha:1.0f];
  
  NSArray *partitionOfThree = @[
                                @[@1,@1,@1],@[@1,@2],
                                @[@2,@1],
                                @[@3]
                                ];
  
  NSArray *partitionOfFour = @[
                               @[@1,@1,@1,@1],
                               @[@1,@2,@1],
                               @[@1,@1,@2],
                               @[@1,@3],
                               @[@3,@1]
                               ];
  
  if (isPad())
    [self reloadLayout:partitionOfFour];
  else
    [self reloadLayout:partitionOfThree];
}

- (void)viewWillAppear:(BOOL)animated {
  
  [super viewWillAppear:animated];
  
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}



#pragma mark Collection delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return [_photos count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  WAPhotoStreamViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPhotoStreamCellID forIndexPath:indexPath];
  
  if (cell) {
    cell.backgroundColor = colorPalette[rand()%[colorPalette count]];
    cell.layer.borderWidth = 1.0f;
    cell.layer.borderColor = [UIColor colorWithWhite:100/255.0 alpha:1.0f].CGColor;
    cell.backgroundView.layer.cornerRadius = 1.0f;
    cell.backgroundView.layer.masksToBounds = YES;
  }
  
  WAFile *photo = (WAFile *)_photos[indexPath.row];
  
  [photo irObserve:@"smallThumbnailImage"
           options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
           context:nil
         withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
           
           dispatch_async(dispatch_get_main_queue(), ^{
             
             ((WAPhotoStreamViewCell *)[collectionView cellForItemAtIndexPath:indexPath]).imageView.image = (UIImage*)toValue;
             
           });
           
         }];
  
  return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  NSInteger width_unit = [_layout[indexPath.row] integerValue];
  
  if (isPad())
    return (CGSize){182*width_unit + 8*(width_unit-1), 192};
  else
    return (CGSize){96*width_unit + 8*(width_unit-1), 96};
  
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
  WADayHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PhotoStreamHeaderView" forIndexPath:indexPath];
  
  headerView.dayLabel.text = [onDate dayString];
  headerView.monthLabel.text = [[onDate localizedMonthShortString] uppercaseString];
  headerView.wdayLabel.text = [[onDate localizedWeekDayFullString] uppercaseString];
  headerView.backgroundColor = [UIColor colorWithWhite:0.16 alpha:1.000];
  headerView.placeHolderView.backgroundColor = [UIColor colorWithWhite:0.260 alpha:1.000];
  headerView.dayLabel.textColor = [UIColor colorWithWhite:0.53 alpha:1.0f];
  headerView.monthLabel.textColor =[UIColor colorWithWhite:0.53 alpha:1.0f];
  headerView.wdayLabel.textColor = [UIColor colorWithWhite:0.53 alpha:1.0f];
  
  return headerView;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  
  WAGalleryViewController *galleryVC = [[WAGalleryViewController alloc] initWithImageFiles:self.photos atIndex:[indexPath row]];
  
  [self.navigationController pushViewController:galleryVC animated:YES];
  
}

@end
