//
//  WASharedEventFlowLayout.m
//  wammer
//
//  Created by Greener Chen on 13/4/11.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WASpotlightSlideFlowLayout.h"

@interface WASpotlightSlideFlowLayout()

@property (nonatomic, assign) CGFloat maxItemSize;
@property (nonatomic, assign) CGFloat minItemSize;
@property (nonatomic, assign) CGFloat itemWidth;

@end
@implementation WASpotlightSlideFlowLayout

- (void) prepareLayout {
  self.scrollDirection = UICollectionViewScrollDirectionVertical;
  self.sectionInset = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
  self.minimumLineSpacing = 0.f;
  
  self.itemWidth = CGRectGetWidth(self.collectionView.frame);
  self.minItemSize = 140.f;
  self.maxItemSize = 275.f;

}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
  return YES;
}

- (CGSize)collectionViewContentSize {
  NSInteger numOfItem = [self.collectionView numberOfItemsInSection:0];
  return CGSizeMake(self.itemWidth, numOfItem * self.minItemSize + self.collectionView.frame.size.height - self.minItemSize);
}

-(NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
  
  NSArray *array = [[super layoutAttributesForElementsInRect:rect] mutableCopy];
  NSMutableArray *newAttributesArray = [NSMutableArray array];
  
  for (UICollectionViewLayoutAttributes *attributes in array) {
    [newAttributesArray addObject:[self relayoutAttributesForAttributes:attributes]];
  }
  
  return [NSArray arrayWithArray:newAttributesArray];
}

- (UICollectionViewLayoutAttributes*)relayoutAttributesForAttributes:(UICollectionViewLayoutAttributes*)attributes {
  CGFloat visibleRectOriginY = self.collectionView.contentOffset.y;
  
  CGFloat itemY = attributes.indexPath.row * self.minItemSize;
  
  if (visibleRectOriginY < 0) {
    
    if (attributes.indexPath.row == 0 ) {
      attributes.frame = CGRectMake(attributes.frame.origin.x, 0, self.itemWidth, self.maxItemSize);

    } else if (attributes.indexPath.row > 0) {
      CGFloat h = (attributes.indexPath.row+1) * self.minItemSize - (self.minItemSize*3 - (self.minItemSize+self.maxItemSize));
      attributes.frame = CGRectMake(attributes.frame.origin.x,
                                    h,
                                    self.itemWidth,
                                    self.minItemSize);
    
    }
    return attributes;
  }

  if (itemY == visibleRectOriginY) {
    attributes.frame = CGRectMake(attributes.frame.origin.x, itemY, self.itemWidth, self.maxItemSize);
    
  } else if (itemY < visibleRectOriginY && itemY > (visibleRectOriginY - self.minItemSize)) {
    CGFloat h = itemY + self.minItemSize - visibleRectOriginY;
    attributes.frame = CGRectMake(attributes.frame.origin.x, itemY, self.itemWidth, (visibleRectOriginY - itemY) + h * self.maxItemSize / self.minItemSize);
    
  } else if (itemY > visibleRectOriginY && itemY <= (visibleRectOriginY + self.minItemSize)) {
    CGFloat h = itemY - visibleRectOriginY;
    attributes.frame = CGRectMake(attributes.frame.origin.x,
                                  visibleRectOriginY + self.maxItemSize * (h / self.minItemSize),
                                  self.itemWidth,
                                  (self.maxItemSize + h) - h * self.maxItemSize / self.minItemSize);
  
  } else if (itemY < visibleRectOriginY) {
    attributes.frame = CGRectMake(attributes.frame.origin.x, itemY, self.itemWidth, self.minItemSize);
    
  } else {
    CGFloat h = (attributes.indexPath.row+1) * self.minItemSize - (self.minItemSize*3 - (self.minItemSize+self.maxItemSize));
    attributes.frame = CGRectMake(attributes.frame.origin.x,
                                  h,
                                  self.itemWidth,
                                  self.minItemSize);
  }
  return attributes;
}
/*
- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {

  UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
  [self relayoutAttributesForAttributes:attributes];
  return attributes;
}

- (UICollectionViewLayoutAttributes*)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
  UICollectionViewLayoutAttributes *attributes = [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
  [self relayoutAttributesForAttributes:attributes];
  return attributes;
}
*/
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
  NSInteger base = (NSInteger)self.collectionView.contentOffset.y / self.minItemSize;
  if (velocity.y > 2.f || velocity.y < -2.f) {
    base = (NSInteger)proposedContentOffset.y / self.minItemSize;
    base += 1;
  } else if (velocity.y > 0){
    base += 1;
  } 
  
  return CGPointMake(proposedContentOffset.x, base * self.minItemSize);
}

@end
