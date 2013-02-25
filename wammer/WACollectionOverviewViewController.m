//
//  WACollectionOverviewViewController.m
//  wammer
//
//  Created by jamie on 13/2/21.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WACollectionOverviewViewController.h"
#import "WAFile+LazyImages.h"
#import "WAGalleryViewController.h"
#import "WACollection.h"

@interface WACollectionOverviewViewController ()

@end

@implementation WACollectionOverviewViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  [self.collectionView registerClass:[UICollectionViewCell class]
          forCellWithReuseIdentifier:@"WACollectionOverviewViewCell"];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return [_collection.files count];
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  
  UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WACollectionOverviewViewCell" forIndexPath:indexPath];
  
  UIImageView *imageView;
  for (UIView *view in [cell subviews]) {
    if ([view isKindOfClass:[UIImageView class]]) {
      imageView = (UIImageView*)view;
    } else {
      imageView = [[UIImageView alloc] initWithFrame:(CGRect){0,0,75,75}];
      [cell addSubview:imageView];
      cell.clipsToBounds = YES;
    }
  }
  
  WAFile *target = (WAFile*)[_collection.files objectAtIndex:[indexPath row]];
  imageView.image = target.smallThumbnailImage;
  
  return (UICollectionViewCell*)cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  WAGalleryViewController *galleryVC = [[WAGalleryViewController alloc]
                                        initWithImageFiles:[_collection.files array]
                                        atIndex:[indexPath row]];
  [self.navigationController pushViewController:galleryVC animated:YES];
}
@end
