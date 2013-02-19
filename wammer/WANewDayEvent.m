//
//  WANewDayEvent.m
//  wammer
//
//  Created by kchiu on 13/2/10.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WANewDayEvent.h"
#import "WAArticle.h"
#import "WAEventViewController.h"
#import "WAFile.h"
#import "NSString+WAAdditions.h"
#import <StackBluriOS/UIImage+StackBlur.h>
#import "WAFile+ImplicitBlobFulfillment.h"

@interface WANewDayEvent ()

@property (nonatomic, readonly) NSUInteger numOfImages;

@end

@implementation WANewDayEvent

- (id)initWithArticle:(WAArticle *)anArticle date:(NSDate *)aDate {

  self = [super init];
  if (self) {
    if (anArticle) {
      __weak WANewDayEvent *wSelf = self;
      [anArticle irObserve:@"files.@count" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
        NSCParameterAssert([NSThread isMainThread]);
        switch ([toValue integerValue]) {
          case 0:
            wSelf.style = WADayEventStyleCheckin;
            break;
          case 1:
            wSelf.style = WADayEventStyleOnePhoto;
            break;
          case 2:
            wSelf.style = WADayEventStyleTwoPhotos;
            break;
          case 3:
            wSelf.style = WADayEventStyleThreePhotos;
            break;
          default:
            wSelf.style = WADayEventStyleFourPhotos;
            break;
        }
      }];
      [anArticle irObserve:@"eventStartDate" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
        NSCParameterAssert([NSThread isMainThread]);
        wSelf.startTime = [toValue copy];
      }];
      [anArticle irObserve:@"text" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
        NSCParameterAssert([NSThread isMainThread]);
        wSelf.eventDescription = [[WAEventViewController attributedDescriptionStringForEvent:anArticle] string];
      }];
      self.representingArticle = anArticle;
    } else {
      self.style = WADayEventStyleNone;
      self.startTime = aDate;
    }
  }
  return self;

}

- (void)dealloc {

  [self.representingArticle irRemoveObserverBlocksForKeyPath:@"files.@count"];
  [self.representingArticle irRemoveObserverBlocksForKeyPath:@"eventStartDate"];
  [self.representingArticle irRemoveObserverBlocksForKeyPath:@"text"];
  for (NSUInteger i = 0; i < self.numOfImages; i++) {
    [self.representingArticle.files[i] irRemoveObserverBlocksForKeyPath:@"smallThumbnailFilePath"];
  }

}

- (NSUInteger)numOfImages {

  switch (self.style) {
    case WADayEventStyleOnePhoto:
      return 1;
    case WADayEventStyleTwoPhotos:
      return 2;
    case WADayEventStyleThreePhotos:
      return 3;
    case WADayEventStyleFourPhotos:
      return 4;
    default:
      return 0;
  }

}

- (void)loadImages {

  if (self.images) {
    return;
  }

  self.images = [NSMutableDictionary dictionary];
  self.imageLoadingOperations = [NSMutableArray array];

  if (self.style == WADayEventStyleNone) {
    self.images[@0] = [[self class] sharedNoEventImage];
    self.backgroundImage = [[self class] sharedNoEventBackgroundImage];
    return;
  }

  __weak WANewDayEvent *wSelf = self;
  for (NSUInteger idx = 0; idx < self.numOfImages; idx++) {
    WAFile *file = self.representingArticle.files[idx];
    [file setDisplayingSmallThumbnail:YES];
    [file irRemoveObserverBlocksForKeyPath:@"smallThumbnailFilePath"];
    [file irObserve:@"smallThumbnailFilePath" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
      // the image displaying operation will be put in a LIFO queue to make UI more responsible to user
      if (toValue) {
        NSString *filePath = [toValue copy];
        [wSelf insertImageDisplayOperationWithFilePath:filePath index:idx];
      } else {
        // show xs thumbnail if small thumbnail does not exist
        UIImage *extraSmallThumbnailImage = [UIImage imageWithContentsOfFile:file.extraSmallThumbnailFilePath];
        if (extraSmallThumbnailImage) {
          wSelf.images[@(idx)] = extraSmallThumbnailImage;
        }
      }
      if (![[[wSelf class] sharedImageDisplayQueue] operationCount]) {
        [wSelf enqueueImageDisplayOperationIfNeeded];
      }
    }];
  }

}

- (void)unloadImages {
  
  for (NSOperation *operation in self.imageLoadingOperations) {
    [operation cancel];
  }
  self.imageLoadingOperations = nil;
  self.images = nil;
  self.backgroundImage = nil;

}

- (void)insertImageDisplayOperationWithFilePath:(NSString *)aFilePath index:(NSUInteger)anIndex {
  
  if (![[NSFileManager defaultManager] fileExistsAtPath:aFilePath]) {
    return;
  }

  NSMutableArray *enqueuedImageFilePaths = [[self class] sharedEnqueuedImageFilePaths];
  NSMutableArray *enqueuedImageDisplayOperations = [[self class] sharedEnqueuedImageDisplayOperations];
  NSUInteger index = [enqueuedImageFilePaths indexOfObject:aFilePath];
  if (index == NSNotFound) {
    __weak WANewDayEvent *wSelf = self;
    [enqueuedImageFilePaths insertObject:aFilePath atIndex:0];
    __block NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
      if ([operation isCancelled]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
	[wSelf enqueueImageDisplayOperationIfNeeded];
        });
        return;
      }
      UIImage *decompressedImage = [aFilePath loadDecompressedImage];
      wSelf.images[@(anIndex)] = decompressedImage;
      if (anIndex == 0) {
        wSelf.backgroundImage = [decompressedImage stackBlur:5];
      }
      dispatch_sync(dispatch_get_main_queue(), ^{
        [wSelf enqueueImageDisplayOperationIfNeeded];
      });
    }];
    [self.imageLoadingOperations addObject:operation];
    [enqueuedImageDisplayOperations insertObject:operation atIndex:0];
  } else {
    [enqueuedImageFilePaths removeObjectAtIndex:index];
    [enqueuedImageFilePaths insertObject:aFilePath atIndex:0];
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

+ (UIImage *)sharedNoEventImage {
  
  static UIImage *noEventImage;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    noEventImage = [UIImage imageNamed:@"WASummaryNoEvent"];
  });
  return noEventImage;
  
}

+ (UIImage *)sharedNoEventBackgroundImage {
  
  static UIImage *backgroundImage;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if ([UIScreen mainScreen].bounds.size.height == 568) {
      backgroundImage = [[UIImage imageNamed:@"WASummaryNoEventBackground~568h"] stackBlur:5.0];
    } else {
      backgroundImage = [[UIImage imageNamed:@"WASummaryNoEventBackground"] stackBlur:5.0];
    }
  });
  return backgroundImage;
  
}

@end
