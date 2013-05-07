//
//  WAPhotoTimelineGalleryLayout.m
//  wammer
//
//  Created by Shen Steven on 4/30/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPhotoTimelineGalleryLayout.h"

@implementation WAPhotoTimelineGalleryLayout

- (void) prepareLayout {
  self.minimumInteritemSpacing = 0.0f;
  self.minimumLineSpacing = 20.0f;
  self.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
  
  CGRect fullScreenBounds = [[UIScreen mainScreen] bounds];
  self.itemSize = CGSizeMake(fullScreenBounds.size.height, fullScreenBounds.size.width);
  self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  self.collectionView.alwaysBounceVertical = NO;
}

//- (CGSize) collectionViewContentSize {
//  NSInteger numOfItems = [self.collectionView numberOfItemsInSection:0];
//  return CGSizeMake((self.collectionView.frame.size.height + self.minimumInteritemSpacing)* numOfItems, self.collectionView.frame.size.width);
//}

//- (NSArray*) layoutAttributesForElementsInRect:(CGRect)rect {
//  
//  NSArray *array = [super layoutAttributesForElementsInRect:rect];
//  for (UICollectionViewLayoutAttributes *attr in array) {
//    NSLog(@"index: %@, frame: %@", attr.indexPath, NSStringFromCGRect(attr.frame));
//  } 
//  
//  return array;
//}

- (CGPoint) targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
  int closestPage = (int)(self.collectionView.contentOffset.x / (self.itemSize.width + self.minimumLineSpacing));
  if (velocity.x > 0)
    closestPage += 1;
  if (closestPage < 0)
    closestPage = 0;
  
  return CGPointMake(closestPage * (self.itemSize.width + self.minimumLineSpacing), proposedContentOffset.y);
  
}
@end
