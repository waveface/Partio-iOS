//
//  WAPhotoTimelineLayout.m
//  wammer
//
//  Created by Shen Steven on 4/5/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPhotoTimelineLayout.h"

@implementation WAPhotoTimelineLayout {
  CGRect origHeaderFrame;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
  
  NSArray *attrs = [super layoutAttributesForElementsInRect:rect];
  
  [attrs enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *attr, NSUInteger idx, BOOL *stop) {
    
    if (attr.representedElementCategory == UICollectionElementCategorySupplementaryView)
      if ([attr.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        CGFloat newOffset = self.collectionView.contentOffset.y;
        
        if (newOffset < 0) {
          
          CGSize origSize = attr.size;
          CGRect newFrame = CGRectMake(0, newOffset, origSize.width, (-newOffset) + origSize.height);
          attr.frame = newFrame;
          attr.size = newFrame.size;
          
        }
      }
    
  }];
  
  return attrs;
  
}

- (BOOL) shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
  return YES;
}


@end
