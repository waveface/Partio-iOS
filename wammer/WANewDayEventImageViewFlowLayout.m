//
//  WANewDayEventImageViewFlowLayout.m
//  wammer
//
//  Created by kchiu on 13/2/11.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WANewDayEventImageViewFlowLayout.h"
#import "WANewDayEventViewCell.h"

@implementation WANewDayEventImageViewFlowLayout

- (CGSize)collectionViewContentSize {

  return self.collectionView.frame.size;

}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {

  NSUInteger numberOfCells = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0];
  switch (numberOfCells) {
    case 1: {
      UICollectionViewLayoutAttributes *attributes0 = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
      attributes0.frame = rect;
      return @[attributes0];
    }
    case 2: {
      UICollectionViewLayoutAttributes *attributes0 = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
      attributes0.frame = CGRectMake(0, 0, rect.size.width/2-1, rect.size.height);
      UICollectionViewLayoutAttributes *attributes1 = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
      attributes1.frame = CGRectMake(rect.size.width/2+1, 0, rect.size.width/2, rect.size.height);
      return @[attributes0, attributes1];
    }
    case 3: {
      UICollectionViewLayoutAttributes *attributes0 = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
      attributes0.frame = CGRectMake(0, 0, rect.size.width/2-1, rect.size.height);
      UICollectionViewLayoutAttributes *attributes1 = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
      attributes1.frame = CGRectMake(rect.size.width/2+1, 0, rect.size.width/2-1, rect.size.height/2-1);
      UICollectionViewLayoutAttributes *attributes2 = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]];
      attributes2.frame = CGRectMake(rect.size.width/2+1, rect.size.height/2+1, rect.size.width/2-1, rect.size.height/2-1);
      return @[attributes0, attributes1, attributes2];
    }
    case 4: {
      UICollectionViewLayoutAttributes *attributes0 = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
      attributes0.frame = CGRectMake(0, 0, rect.size.width/2-1, rect.size.height);
      UICollectionViewLayoutAttributes *attributes1 = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
      attributes1.frame = CGRectMake(rect.size.width/2+1, 0, rect.size.width/2-1, rect.size.height/2-1);
      UICollectionViewLayoutAttributes *attributes2 = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]];
      attributes2.frame = CGRectMake(rect.size.width/2+1, rect.size.height/2+1, (rect.size.width/2-1)/2-1, rect.size.height/2-1);
      UICollectionViewLayoutAttributes *attributes3 = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:3 inSection:0]];
      attributes3.frame = CGRectMake(rect.size.width/2+1+(rect.size.width/2-1)/2+1, rect.size.height/2+1, (rect.size.width/2-1)/2-1, rect.size.height/2-1);
      return @[attributes0, attributes1, attributes2, attributes3];
    }
    default:
      NSAssert(NO, @"unexpected number of cells %d", numberOfCells);
      break;
  }
  
  return nil;

}

@end
