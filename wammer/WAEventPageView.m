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
@property (nonatomic) BOOL shouldDisplayImages;

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

  self.shouldDisplayImages = YES;

  if ([self.representingArticle.files count] > 0) {
    __weak WAEventPageView *wSelf = self;
    [self.imageViews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIImageView *imageView, NSUInteger idx, BOOL *stop) {
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
	[wSelf insertImageDisplayOperationWithFilePath:filePath imageView:imageView isBackgroundImage:(idx == 0)];
	if (![[[wSelf class] sharedImageDisplayQueue] operationCount]) {
	  [wSelf enqueueImageDisplayOperationIfNeeded];
	}
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
  self.shouldDisplayImages = NO;

  for (UIImageView *imageView in self.imageViews) {
    imageView.image = nil;
  }
  self.blurredBackgroundImage = nil;

}

- (void)insertImageDisplayOperationWithFilePath:(NSString *)filePath imageView:(UIImageView *)imageView isBackgroundImage:(BOOL)isBackgroundImage {

  NSMutableArray *enqueuedImageFilePaths = [[self class] sharedEnqueuedImageFilePaths];
  NSMutableArray *enqueuedImageDisplayOperations = [[self class] sharedEnqueuedImageDisplayOperations];
  NSUInteger index = [enqueuedImageFilePaths indexOfObject:filePath];
  if (index == NSNotFound) {
    __weak WAEventPageView *wSelf = self;
    [enqueuedImageFilePaths insertObject:filePath atIndex:0];
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
      if (imageView.image || !wSelf.shouldDisplayImages) {
        dispatch_sync(dispatch_get_main_queue(), ^{
	[wSelf enqueueImageDisplayOperationIfNeeded];
        });
        return;
      }
      UIImage *decompressedImage = [filePath loadDecompressedImage];
      UIImage *backgroundImage = [decompressedImage stackBlur:5];
      dispatch_sync(dispatch_get_main_queue(), ^{
        if (wSelf.shouldDisplayImages) {
	if (isBackgroundImage) {
	  wSelf.blurredBackgroundImage = backgroundImage;
	}
	imageView.image = decompressedImage;
        }
        [wSelf enqueueImageDisplayOperationIfNeeded];
      });
    }];
    [enqueuedImageDisplayOperations insertObject:operation atIndex:0];
  } else {
    [enqueuedImageFilePaths removeObjectAtIndex:index];
    [enqueuedImageFilePaths insertObject:filePath atIndex:0];
    NSBlockOperation *operation = [enqueuedImageDisplayOperations objectAtIndex:index];
    [enqueuedImageDisplayOperations removeObjectAtIndex:index];
    [enqueuedImageDisplayOperations insertObject:operation atIndex:0];
  }

}

- (void)enqueueImageDisplayOperationIfNeeded {

  NSMutableArray *enqueuedImageFilePaths = [[self class] sharedEnqueuedImageFilePaths];
  NSMutableArray *enqueuedImageDisplayOperations = [[self class] sharedEnqueuedImageDisplayOperations];
  if ([enqueuedImageFilePaths count]) {
    [enqueuedImageFilePaths removeObjectAtIndex:0];
    NSBlockOperation *operation = enqueuedImageDisplayOperations[0];
    [enqueuedImageDisplayOperations removeObjectAtIndex:0];
    [[[self class] sharedImageDisplayQueue] addOperation:operation];
  }

}

- (void)dealloc {

  if ([self.representingArticle.files count] > 0) {
    [self.imageViews enumerateObjectsUsingBlock:^(UIImageView *imageView, NSUInteger idx, BOOL *stop) {
      [self.representingArticle.files[idx] irRemoveObserverBlocksForKeyPath:@"smallThumbnailImage" context:&kWAEventPageViewKVOContext];
    }];
  }
  
}

+ (NSMutableArray *)sharedEnqueuedImageFilePaths {

  static NSMutableArray *enqueuedImageFilePaths;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    enqueuedImageFilePaths = [NSMutableArray array];
  });
  return enqueuedImageFilePaths;

}

+ (NSMutableArray *)sharedEnqueuedImageDisplayOperations {

  static NSMutableArray *enqueuedImageLoadingOperations;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    enqueuedImageLoadingOperations = [NSMutableArray array];
  });
  return enqueuedImageLoadingOperations;

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
