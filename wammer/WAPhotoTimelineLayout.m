//
//  WAPhotoTimelineLayout.m
//  wammer
//
//  Created by Shen Steven on 4/5/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPhotoTimelineLayout.h"

@interface WAPhotoTimelineLayout ()

@property (nonatomic, strong, readonly) NSArray *layouts;
@property (nonatomic, assign, readonly) NSInteger numberOfItems;

@end

@implementation WAPhotoTimelineLayout {
  CGRect origHeaderFrame;
}

- (void) prepareLayout {
  self.minimumLineSpacing = 8;
  self.minimumInteritemSpacing = 0;
  self.sectionInset = UIEdgeInsetsMake(0, 5, 0, 0);
  self.itemSize = CGSizeMake(1, 1);
  self.scrollDirection = UICollectionViewScrollDirectionVertical;
//  self.collectionView.bounces = YES;
//  self.collectionView.alwaysBounceVertical = YES;

  _numberOfItems = [self.collectionView numberOfItemsInSection:0];
  
  _layouts = @[
               @{@"numOfItems": @(4),
                 @"width": @(self.collectionView.frame.size.width),
                 @"height": @(203),
                 @"frames": @[
                     @{@"x": @(0), @"y": @(0), @"width": @(207.0f), @"height": @(203.0f)},
                     @{@"x": @(212), @"y":@(0), @"width": @(98.0f), @"height": @(65.0f)},
                     @{@"x": @(212), @"y":@(70), @"width": @(98.0f), @"height":@(65.0f)},
                     @{@"x": @(212), @"y":@(140), @"width": @(98.0f), @"height": @(64.0f)}
                     ]},
               @{@"numOfItems": @(3),
                 @"width": @(self.collectionView.frame.size.width),
                 @"height": @(83),
                 @"frames": @[
                     @{@"x": @(0), @"y": @(0), @"width": @(100), @"height": @(83)},
                     @{@"x": @(105), @"y": @(0), @"width": @(100), @"height": @(83)},
                     @{@"x": @(210), @"y": @(0), @"width": @(100), @"height": @(83)}
                     ]
                 },
               @{@"numOfItems": @(2),
                 @"width": @(self.collectionView.frame.size.width),
                 @"height": @(123),
                 @"frames": @[
                     @{@"x": @(0), @"y": @(0), @"width": @(151), @"height": @(123)},
                     @{@"x": @(159), @"y": @(0), @"width": @(151), @"height": @(123)}
                     ]
                 },
               @{@"numOfItems": @(1),
                 @"width": @(self.collectionView.frame.size.width),
                 @"height": @(203),
                 @"frames": @[
                     @{@"x": @(0), @"y": @(0), @"width": @(310), @"height":@(203)}
                     ]}
               ];

  
}

- (CGSize) collectionViewContentSize {

  CGFloat height = 250;
  NSInteger itemsCounted = 0, layoutIdx = 0;
  while (itemsCounted < self.numberOfItems) {
    
    height += ([self.layouts[layoutIdx][@"height"] floatValue] + self.minimumLineSpacing);
    itemsCounted += [self.layouts[layoutIdx][@"numOfItems"] intValue];
    
    layoutIdx += 1;
    if (layoutIdx == 4)
      layoutIdx = 0;
  }

  return CGSizeMake(self.collectionView.frame.size.width, height);
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAttributes:(UICollectionViewLayoutAttributes*)attr {

  NSAssert(attr, @"Attributes is required");
  
  CGFloat hBase = 250;
  NSInteger layoutIndex = 0;
  NSInteger itemsBeforeLayout = 0;
  while (itemsBeforeLayout < self.numberOfItems) {
    if (attr.indexPath.row < itemsBeforeLayout + [self.layouts[layoutIndex][@"numOfItems"] intValue]) {
      
      NSArray *frames = self.layouts[layoutIndex][@"frames"];
      NSInteger idxInFrames = attr.indexPath.row - itemsBeforeLayout;
      CGFloat x = [frames[idxInFrames][@"x"] floatValue];
      CGFloat y = [frames[idxInFrames][@"y"] floatValue];
      CGFloat w = [frames[idxInFrames][@"width"] floatValue];
      CGFloat h = [frames[idxInFrames][@"height"] floatValue];
      
      attr.frame = CGRectMake(x + self.sectionInset.left, hBase + y, w, h);
      return attr;
      
    } else {
      
      hBase += ([self.layouts[layoutIndex][@"height"] floatValue] + self.minimumLineSpacing);
      itemsBeforeLayout += [self.layouts[layoutIndex][@"numOfItems"] intValue];
      layoutIndex ++;
      if (layoutIndex == 4)
        layoutIndex = 0;
      
    }
    
  }
  
  return attr;

}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {

  NSArray *attrs = [super layoutAttributesForElementsInRect:(CGRect){CGPointZero, [self collectionViewContentSize]}];
  
  [attrs enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *attr, NSUInteger idx, BOOL *stop) {
    
    if (attr.representedElementCategory == UICollectionElementCategorySupplementaryView) {
      if ([attr.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        CGFloat newOffset = self.collectionView.contentOffset.y;
        
        if (newOffset < 0) {
          
          CGSize origSize = attr.size;
          CGRect newFrame = CGRectMake(0, newOffset, origSize.width, (-newOffset) + origSize.height);
          attr.frame = newFrame;
          attr.size = newFrame.size;
        }
      }
    } else if (attr.representedElementCategory == UICollectionElementCategoryCell) {
    
      [self layoutAttributesForItemAttributes:attr];
      
    }
    
  }];
  
  return attrs;
  
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {

  UICollectionViewLayoutAttributes *attr = [super layoutAttributesForItemAtIndexPath:indexPath];
  if (attr)
    return [self layoutAttributesForItemAttributes:attr];
  
  attr = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];

  return [self layoutAttributesForItemAttributes:attr];
}

- (BOOL) shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
  return YES;
}


@end
