//
//  WAEventPageView.m
//  wammer
//
//  Created by kchiu on 13/1/22.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAEventPageView.h"
#import "WAArticle.h"
#import "WASummaryViewController.h"
#import "WADataStore.h"
#import "WAFile+ImplicitBlobFulfillment.h"
#import "NSString+WAAdditions.h"
#import <StackBluriOS/UIImage+StackBlur.h>
#import "UIImageView+WAAdditions.h"

static NSString * kWAEventPageViewKVOContext = @"WAEventPageViewKVOContext";

@interface WAEventPageView ()

@property (nonatomic, strong) WAArticle *representingArticle;
@property (nonatomic) BOOL shouldLoadImages;

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

- (void)loadImages {

  NSParameterAssert([NSThread isMainThread]);
  self.shouldLoadImages = YES;

  if ([self.representingArticle.files count] > 0) {
    __weak WAEventPageView *wSelf = self;
    [self.imageViews enumerateObjectsUsingBlock:^(UIImageView *imageView, NSUInteger idx, BOOL *stop) {
      if (imageView.image) {
        return;
      }
      imageView.clipsToBounds = YES;
      WAFile *file = _representingArticle.files[idx];
      [file setDisplayingSmallThumbnail:YES];
      [file irRemoveObserverBlocksForKeyPath:@"smallThumbnailFilePath" context:&kWAEventPageViewKVOContext];
      [file irObserve:@"smallThumbnailFilePath" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:&kWAEventPageViewKVOContext withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
        if (toValue) {
	NSString *filePath = [toValue copy];
	[[[wSelf class] sharedImageDisplayQueue] addOperationWithBlock:^{
	  if (imageView.image || !wSelf.shouldLoadImages) {
	    return;
	  }
	  UIImage *decompressedImage = [filePath loadDecompressedImage];
	  UIImage *backgroundImage = [decompressedImage stackBlur:5];
	  dispatch_sync(dispatch_get_main_queue(), ^{
	    if (wSelf.shouldLoadImages) {
	      if (idx == 0) {
	        wSelf.blurredBackgroundImage = backgroundImage;
	      }
	      imageView.image = decompressedImage;
	    }
	  });
	}];
        }
      }];
    }];
  } else {
    UIImageView *imageView = self.imageViews[0];
    if (!imageView.image) {
      imageView.image = [WASummaryViewController sharedBackgroundImage];
      self.blurredBackgroundImage = [WASummaryViewController sharedBackgroundImage];
    }
  }

}

- (void)unloadImages {

  NSParameterAssert([NSThread isMainThread]);
  self.shouldLoadImages = NO;

  for (UIImageView *imageView in self.imageViews) {
    imageView.image = nil;
  }
  self.blurredBackgroundImage = nil;

}

- (void)dealloc {

  if ([self.representingArticle.files count] > 0) {
    [self.imageViews enumerateObjectsUsingBlock:^(UIImageView *imageView, NSUInteger idx, BOOL *stop) {
      [self.representingArticle.files[idx] irRemoveObserverBlocksForKeyPath:@"smallThumbnailImage" context:&kWAEventPageViewKVOContext];
    }];
  }
  
}

+ (NSOperationQueue *)sharedImageDisplayQueue {

  static NSOperationQueue *queue;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:1];
  });
  return queue;

}

@end
