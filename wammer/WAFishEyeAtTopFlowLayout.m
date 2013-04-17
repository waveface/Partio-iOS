//
//  WASharedEventFlowLayout.m
//  wammer
//
//  Created by Greener Chen on 13/4/11.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAFishEyeAtTopFlowLayout.h"

@implementation WAFishEyeAtTopFlowLayout

#define ITEM_WIDTH 320.f
#define ITEM_HEIGHT 140.f
#define LENGTHEN_HEIGHT 275.f
#define ACTIVE_DISTANCE 207.5f 
#define ScreenRect (CGRect)([[UIScreen mainScreen] applicationFrame])

- (id)init
{
  self = [super init];
  if (self) {
    self.itemSize = CGSizeMake(ITEM_WIDTH, ITEM_HEIGHT);
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
  NSArray *array = [super layoutAttributesForElementsInRect:rect];
  CGRect visibleRect;
  visibleRect.origin = self.collectionView.contentOffset;
  visibleRect.size = self.collectionView.bounds.size;
  
  for (UICollectionViewLayoutAttributes *attributes in array) {
    if (CGRectIntersectsRect(attributes.frame, rect)) {
      CGFloat distance = (visibleRect.origin.y + LENGTHEN_HEIGHT/2.f) - attributes.center.y;
      CGFloat normalizedDistance = distance / ITEM_HEIGHT;
      
      if (ABS(distance) < ITEM_HEIGHT &&
          attributes.center.y > (visibleRect.origin.y + LENGTHEN_HEIGHT/2.f ) &&
          attributes.center.y <= (visibleRect.origin.y + LENGTHEN_HEIGHT + ITEM_HEIGHT/2.f)) {
//        if (!attributes.frame.origin.y) {
//          continue;
//        }
        CGFloat zoom = 1 + (1 - ABS(normalizedDistance)) * (LENGTHEN_HEIGHT / ITEM_HEIGHT - 1);
        attributes.size = CGSizeMake(ITEM_WIDTH, attributes.size.height * zoom);
        attributes.zIndex = round(zoom);
      }
    }
  }
  
  return array;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
  CGFloat offsetAjustment = MAXFLOAT;
  CGFloat targetItemVerticalCenter = proposedContentOffset.y + LENGTHEN_HEIGHT/2.f;
  
  CGRect targetRect = CGRectMake(0.f, proposedContentOffset.y, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
  NSArray *array = [super layoutAttributesForElementsInRect:targetRect];
  
  for (UICollectionViewLayoutAttributes *attributes in array) {
    CGFloat itemVerticalCenter = attributes.center.y;
    if (ABS(itemVerticalCenter - targetItemVerticalCenter) < offsetAjustment) {
      offsetAjustment = itemVerticalCenter - targetItemVerticalCenter;
    }
  }
  
  return CGPointMake(proposedContentOffset.x, proposedContentOffset.y + offsetAjustment);
}

@end
