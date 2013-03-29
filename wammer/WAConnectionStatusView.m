//
//  WAConnectionStatusView.m
//  wammer
//
//  Created by Shen Steven on 1/30/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAConnectionStatusView.h"
#import "WARemoteInterface.h"
#import "WASyncManager.h"
#import "WAFetchManager.h"
#import "WAAppDelegate.h"
#import "WAAppDelegate_iOS.h"
#import "UIImage+IRAdditions.h"

static NSString * const kWASyncingAnimation = @"WASyncingAnimation";

@interface WAConnectionStatusView ()

@property (nonatomic, strong) WARemoteInterface *remoteInterface;

@end

@implementation WAConnectionStatusView {
  BOOL isExchangingData;
}

+ (id) viewFromNib {
  
  __weak id wSelf = self;
  return [[[[UINib nibWithNibName:NSStringFromClass(self) bundle:[NSBundle bundleForClass:self]] instantiateWithOwner:nil options:nil] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock: ^ (id evaluatedObject, NSDictionary *bindings) {
	return [evaluatedObject isKindOfClass:wSelf];
  }]] lastObject];
  
}

- (id)init
{
  self = [super init];
  if (self) {
	  
    isExchangingData = NO;
    
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.refreshImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.refreshImageView.image = [[UIImage imageNamed:@"WARefreshGlyph"] irSolidImageWithFillColor:[UIColor whiteColor] shadow:nil];
    
	self.remoteInterface = [WARemoteInterface sharedInterface];
	[self.remoteInterface addObserver:self
						   forKeyPath:@"networkState"
							  options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
							  context:nil];
   
    WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
    [appDelegate.syncManager addObserver:self
                              forKeyPath:@"isSyncing"
                                 options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                                 context:nil];

    [appDelegate.fetchManager addObserver:self
                               forKeyPath:@"isFetching"
                                  options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                                  context:nil];
  }
  return self;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  __weak WAConnectionStatusView *wSelf = self;

  if ([keyPath isEqualToString:@"networkState"]) {
    if ([NSThread isMainThread])
      [self updateNetworkStatus];
    else
      dispatch_async(dispatch_get_main_queue(), ^{
        [wSelf updateNetworkStatus];
      });

  } else if ([keyPath isEqualToString:@"isFetching"] || [keyPath isEqualToString:@"isSyncing"]) {
    if ([NSThread isMainThread])
      [self updateSyncStatus];
    else
      dispatch_async(dispatch_get_main_queue(), ^{
        [wSelf updateSyncStatus];
      });
  }
}

- (void) updateNetworkStatus {
  NSString *text = nil;
  UIImage *image = nil;
  
  if ([self.remoteInterface hasReachableCloud] && ![self.remoteInterface hasReachableStation]) {
	
    text = NSLocalizedString(@"CLOUD_NAME", @"AOStream Cloud Name");
    image = [UIImage imageNamed:@"cloud"];
    
  } else if ([self.remoteInterface hasReachableStation]) {
    
    if ([self.remoteInterface.monitoredHosts count]) {
      text = [self.remoteInterface.monitoredHosts[0] name];
      image = [UIImage imageNamed:@"station"];
    } else {
      text = NSLocalizedString(@"NO_STATION_INSTALLED", @"Cell title in connection status view controller");
      image = [UIImage imageNamed:@"station"];
    }
    
  } else {
    
    text = NSLocalizedString(@"NO_INTERNET_CONNECTION", @"No internet connection");
    image = [UIImage imageNamed:@"nointernetaccess"];
    
  }
  
  if (text || image) {
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.textLabel.text = text;
                       self.imageView.image = image;
                     } completion:nil];
  }
  
}

- (void) updateSyncStatus {
  
  WASyncManager *syncManager = [(WAAppDelegate_iOS *)AppDelegate() syncManager];
  WAFetchManager *fetchManager = [(WAAppDelegate_iOS *)AppDelegate() fetchManager];
  
  if (syncManager.isSyncing) {
    
    if (syncManager.isSyncFail) {
      
      [self stopRefreshingIndicatorAnimation];
      self.syncStatusText.text = NSLocalizedString(@"PHOTO_UPLOAD_STATUS_BAR_FAIL", @"String on customized status bar");

    } else if (syncManager.needingSyncFilesCount) {
      
      [self startRefreshingIndicatorAnimation];
      self.syncStatusText.text = [NSString stringWithFormat:NSLocalizedString(@"PHOTO_UPLOAD_STATUS_BAR_UPLOADING", @"String on customized status bar"), syncManager.needingSyncFilesCount - syncManager.syncedFilesCount];
      
    } else if (syncManager.needingImportFilesCount) {

      [self startRefreshingIndicatorAnimation];
      self.syncStatusText.text = [NSString stringWithFormat:NSLocalizedString(@"PHOTO_UPLOAD_STATUS_BAR_IMPORTING", @"String on customized status bar"), syncManager.importedFilesCount, syncManager.needingImportFilesCount];
        
    }
  
  } else if (fetchManager.isFetching) {
    
    [self startRefreshingIndicatorAnimation];
    self.syncStatusText.text = NSLocalizedString(@"PHOTO_UPLOAD_STATUS_BAR_SYNCING", @"String on customized status bar");
    
  } else {
    
    [self stopRefreshingIndicatorAnimation];
    self.syncStatusText.text = NSLocalizedString(@"PHOTO_UPLOAD_STATUS_BAR_COMPLETE", @"String on customized status bar");
    
  }

}

- (void) startRefreshingIndicatorAnimation {
  
  if (isExchangingData)
    return;
  
  isExchangingData = YES;
  [self indicatorAnimation];
}

- (void) indicatorAnimation {
  if (![self.refreshImageView.layer animationForKey:kWASyncingAnimation]) {
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = @(-M_PI);
    rotationAnimation.duration = 1.5;
    rotationAnimation.repeatCount = 1;
    rotationAnimation.cumulative = YES;
    rotationAnimation.delegate = self;
    rotationAnimation.removedOnCompletion = YES;
    [self.refreshImageView.layer addAnimation:rotationAnimation forKey:kWASyncingAnimation];
  }
  
}

- (void) stopRefreshingIndicatorAnimation {
  [self.refreshImageView.layer removeAnimationForKey:kWASyncingAnimation];
  isExchangingData = NO;
}

#pragma mark - Core Animation delegates

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
  
  NSParameterAssert([NSThread isMainThread]);
  
  if (!flag) {
    isExchangingData = NO;
    [self.refreshImageView.layer removeAnimationForKey:kWASyncingAnimation];
    return;
  }
  
  if (isExchangingData) {
    [self indicatorAnimation];
  }
  
}


- (void) dealloc {
  
  [self.remoteInterface removeObserver:self forKeyPath:@"networkState"];
  WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
  [appDelegate.syncManager removeObserver:self forKeyPath:@"isSyncing"];
  [appDelegate.fetchManager removeObserver:self forKeyPath:@"isFetching"];
  
}

@end
