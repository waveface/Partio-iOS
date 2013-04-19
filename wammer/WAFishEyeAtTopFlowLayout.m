//
//  WASharedEventFlowLayout.m
//  wammer
//
//  Created by Greener Chen on 13/4/11.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAFishEyeAtTopFlowLayout.h"

@interface WAFishEyeAtTopFlowLayout()

@property (nonatomic, assign) CGFloat maxItemSize;
@property (nonatomic, assign) CGFloat minItemSize;
@property (nonatomic, assign) CGFloat itemWidth;

@end
@implementation WAFishEyeAtTopFlowLayout

- (id)initWithMaxItemSize:(CGFloat)maxItemSize minItemSize:(CGFloat)minItemSize itemWidth:(CGFloat)itemWidth
{
  self = [super init];
  if (self) {
    self.maxItemSize = maxItemSize;
    self.minItemSize = minItemSize;
    self.itemWidth = itemWidth;
    
    self.itemSize = CGSizeMake(itemWidth, minItemSize);
    self.scrollDirection = UICollectionViewScrollDirectionVertical;
    self.sectionInset = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
    self.minimumLineSpacing = 0.f;
    
  }
  
  return self;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
  return YES;
}

-(NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
  CGFloat visibleRectOriginY = self.collectionView.contentOffset.y;
  
  NSMutableArray *array = [[super layoutAttributesForElementsInRect:rect] mutableCopy];

  for (UICollectionViewLayoutAttributes *attributes in array) {
    CGFloat itemY = attributes.indexPath.row * self.minItemSize;
    
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
  }
  
  return array;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
  CGFloat offsetAjustment = MAXFLOAT;
  CGFloat targetItemY = proposedContentOffset.y;
  
  CGRect targetRect = CGRectMake(0.f, proposedContentOffset.y, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
  NSArray *array = [super layoutAttributesForElementsInRect:targetRect];
  
  for (UICollectionViewLayoutAttributes *attributes in array) {
    CGFloat itemY = attributes.frame.origin.y;
    if (ABS(itemY - targetItemY) < offsetAjustment) {
      offsetAjustment = itemY - targetItemY;
    }
  }
  
  return CGPointMake(proposedContentOffset.x, proposedContentOffset.y + offsetAjustment);
}

@end
