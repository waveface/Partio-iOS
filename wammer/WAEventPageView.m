//
//  WAEventPageView.m
//  wammer
//
//  Created by kchiu on 13/1/22.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAEventPageView.h"
#import "WAArticle.h"

@interface WAEventPageView ()

@property (nonatomic, strong) WAArticle *representingArticle;

@end

@implementation WAEventPageView

+ (WAEventPageView *)viewWithRepresentingArticle:(WAArticle *)article {

  WAEventPageView *view = nil;

  switch ([article.files count]) {
    case 0:
    case 1:
      view = [[[UINib nibWithNibName:@"WAEventPageView-ImageStack-1" bundle:[NSBundle mainBundle]] instantiateWithOwner:nil options:nil] lastObject];
      break;
    case 2:
      view = [[[UINib nibWithNibName:@"WAEventPageView-ImageStack-2" bundle:[NSBundle mainBundle]] instantiateWithOwner:nil options:nil] lastObject];
      break;
    case 3:
      view = [[[UINib nibWithNibName:@"WAEventPageView-ImageStack-3" bundle:[NSBundle mainBundle]] instantiateWithOwner:nil options:nil] lastObject];
      break;
    default:
      view = [[[UINib nibWithNibName:@"WAEventPageView-ImageStack-4" bundle:[NSBundle mainBundle]] instantiateWithOwner:nil options:nil] lastObject];
      break;
  };

  for (UIView *containerView in view.containerViews) {
    containerView.layer.cornerRadius = 10.0;
  }

  view.representingArticle = article;

  return view;

}

- (void)setRepresentingArticle:(WAArticle *)representingArticle {

  _representingArticle = representingArticle;

  [self.imageViews enumerateObjectsUsingBlock:^(UIImageView *imageView, NSUInteger idx, BOOL *stop) {
    imageView.clipsToBounds = YES;
    if ([representingArticle.files count] > 0) {
      [representingArticle.files[idx] irObserve:@"smallThumbnailImage" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
        imageView.image = toValue;
      }];
    }
  }];
  
}

@end
