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
#import "WAEventDescriptionView.h"
#import "WAEventViewController.h"
#import "WAAnnotation.h"
#import "MKMapView+ZoomLevel.h"

static NSString * kWAEventPageViewKVOContext = @"WAEventPageViewKVOContext";

typedef NS_ENUM(NSInteger, WACurrentlyDisplayingImage) {
  WACurrentlyNotDisplayingImage,
  WACurrentlyDisplayingExtraSmallThumbnailImage,
  WACurrentlyDisplayingSmallThumbnailImage,
  WACurrentlyDisplayingEmptyImage
};

@interface WAEventPageView ()

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic) BOOL shouldDisplayImages;

@end

@implementation WAEventPageView

+ (NSDateFormatter *)sharedDateFormatter {
  
  static NSDateFormatter *formatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"h:mm a"];
  });
  return formatter;
  
}

+ (WAEventPageView *)viewWithRepresentingArticle:(WAArticle *)article {

  WAEventPageView *view = nil;

  if (article) {
    switch ([article.files count]) {
      case 0:
        view = [[[UINib nibWithNibName:@"WAEventPageView-Checkin" bundle:[NSBundle mainBundle]] instantiateWithOwner:nil options:nil] lastObject];
        break;
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
  } else {
    view = [[[UINib nibWithNibName:@"WAEventPageView-ImageStack-1" bundle:[NSBundle mainBundle]] instantiateWithOwner:nil options:nil] lastObject];
  }

  NSParameterAssert([view.containerViews count] == 1);
  [view.containerViews[0] layer].cornerRadius = 10.0;

  view.representingArticle = article;

  if (article) {
    WAEventDescriptionView *eventDescriptionView = [WAEventDescriptionView viewFromNib];
    eventDescriptionView.timeLabel.text = [[[self class] sharedDateFormatter] stringFromDate:article.eventStartDate];
    [view.representingArticle irObserve:@"text" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
      eventDescriptionView.descriptionLabel.text = [[WAEventViewController attributedDescriptionStringForEvent:article] string];
    }];
    [view.containerViews[0] addSubview:eventDescriptionView];
    view.descriptionView = eventDescriptionView;
  }

  return view;

}

- (void)loadImages {

  NSParameterAssert([NSThread isMainThread]);

  self.shouldDisplayImages = YES;

  if (self.representingArticle) {
    if ([self.representingArticle.files count] > 0) {
      __weak WAEventPageView *wSelf = self;
      [self.imageViews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIImageView *imageView, NSUInteger idx, BOOL *stop) {
        if (imageView.tag == WACurrentlyDisplayingSmallThumbnailImage) {
	return;
        }
        imageView.clipsToBounds = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        WAFile *file = _representingArticle.files[idx];
        [file setDisplayingSmallThumbnail:YES];
        [file irRemoveObserverBlocksForKeyPath:@"smallThumbnailFilePath" context:&kWAEventPageViewKVOContext];
        [file irObserve:@"smallThumbnailFilePath" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:&kWAEventPageViewKVOContext withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
	// the image displaying operation will be put in a LIFO queue to make UI more responsible to user
	if (toValue) {
	  NSString *filePath = [toValue copy];
	  [wSelf insertImageDisplayOperationWithFilePath:filePath
				         imageType:WACurrentlyDisplayingSmallThumbnailImage
				         imageView:imageView
				 isBackgroundImage:(idx == 0)];
	} else {
	  // show xs thumbnail if small thumbnail does not exist
	  NSString *filePath = [file.extraSmallThumbnailFilePath copy];
	  [wSelf insertImageDisplayOperationWithFilePath:filePath
				         imageType:WACurrentlyDisplayingExtraSmallThumbnailImage
				         imageView:imageView
				 isBackgroundImage:(idx == 0)];
	}
	if (![[[wSelf class] sharedImageDisplayQueue] operationCount]) {
	  [wSelf enqueueImageDisplayOperationIfNeeded];
	}
        }];
      }];
    } else {
      if (self.representingArticle.location) {
        if (!self.mapView) {
	MKMapView *mapView = [[MKMapView alloc] initWithFrame:[self.containerViews[0] frame]];
	[mapView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[self.containerViews[0] insertSubview:mapView belowSubview:self.descriptionView];
	[self.containerViews[0] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[mapView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(mapView)]];
	[self.containerViews[0] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[mapView]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(mapView)]];
	self.mapView = mapView;

	CLLocationCoordinate2D center = {[self.representingArticle.location.latitude floatValue], [self.representingArticle.location.longitude floatValue]};
	NSUInteger zoomLevel = 14;
	NSMutableArray *checkins = [NSMutableArray array];
	for (WALocation *loc in self.representingArticle.checkins) {
	  WAAnnotation *pin = [[WAAnnotation alloc] init];
	  CLLocationCoordinate2D checkinCenter = {[loc.latitude floatValue], [loc.longitude floatValue]};
	  pin.coordinate = checkinCenter;
	  if (loc.name) {
	    pin.title = loc.name;
	  }
	  [checkins addObject:pin];
	}
	self.mapView.delegate = self;
	[self.mapView setCenterCoordinate:center zoomLevel:zoomLevel animated:NO];
	[self.mapView addAnnotations:checkins];
        }
      }
    }
  } else {
    UIImageView *imageView = self.imageViews[0];
    imageView.clipsToBounds = YES;
    // the resource image has round corners and is hard to fill in the container view, so we apply center mode here
    imageView.contentMode = UIViewContentModeCenter;
    if (imageView.tag != WACurrentlyDisplayingEmptyImage) {
      imageView.image = [[self class] sharedNoEventImage];
      self.blurredBackgroundImage = [[self class] sharedNoEventBackgroundImage];
      imageView.tag = WACurrentlyDisplayingEmptyImage;
    }
  }

}

- (void)unloadImages {

  NSParameterAssert([NSThread isMainThread]);
  self.shouldDisplayImages = NO;

  for (UIImageView *imageView in self.imageViews) {
    imageView.image = nil;
    imageView.tag = WACurrentlyNotDisplayingImage;
  }
  
  self.blurredBackgroundImage = nil;
  
  [self.mapView removeFromSuperview];
  self.mapView.delegate = nil;
  self.mapView = nil;

}

- (void)insertImageDisplayOperationWithFilePath:(NSString *)filePath imageType:(NSInteger)displayingImageType imageView:(UIImageView *)imageView isBackgroundImage:(BOOL)isBackgroundImage {

  if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    return;
  }
  
  NSMutableArray *enqueuedImageFilePaths = [[self class] sharedEnqueuedImageFilePaths];
  NSMutableArray *enqueuedImageDisplayOperations = [[self class] sharedEnqueuedImageDisplayOperations];
  NSUInteger index = [enqueuedImageFilePaths indexOfObject:filePath];
  if (index == NSNotFound) {
    __weak WAEventPageView *wSelf = self;
    [enqueuedImageFilePaths insertObject:filePath atIndex:0];
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
      if (imageView.tag == displayingImageType || imageView.tag == WACurrentlyDisplayingSmallThumbnailImage || !wSelf.shouldDisplayImages) {
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
	[imageView addCrossFadeAnimationWithTargetImage:decompressedImage];
	imageView.tag = displayingImageType;
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
      [self.representingArticle.files[idx] irRemoveObserverBlocksForKeyPath:@"smallThumbnailFilePath" context:&kWAEventPageViewKVOContext];
    }];
    [self.representingArticle irRemoveObserverBlocksForKeyPath:@"text"];
  }
  
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

+ (UIImage *)sharedNoEventImage {

  static UIImage *noEventImage;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    noEventImage = [UIImage imageNamed:@"WASummaryNoEvent"];
  });
  return noEventImage;

}

+ (UIImage *)sharedAnnotationImage {

  static UIImage *annotationImage;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    annotationImage = [UIImage imageNamed:@"pindrop"];
  });
  return annotationImage;

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

#pragma mark - MKMapView delegates

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {

  static NSString *annotationIdentifier = @"EventMapView-Annotation";
  MKAnnotationView *annView = (MKAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
  if (annView == nil) {
    annView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
  }
  
  annView.canShowCallout = NO;
  annView.draggable = NO;
  annView.image = [[self class] sharedAnnotationImage];
  return annView;

}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
  
  __weak WAEventPageView *wSelf = self;

  double delayInSeconds = 5.0;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    UIGraphicsBeginImageContext(wSelf.mapView.frame.size);
    [wSelf.mapView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *mapImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    wSelf.blurredBackgroundImage = mapImage;
  });
  
}

@end
