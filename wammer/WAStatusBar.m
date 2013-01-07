//
//  WAStatusBar.m
//  wammer
//
//  Created by kchiu on 12/11/15.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAStatusBar.h"
#import "UIImage+IRAdditions.h"

#define kStatusBarHeight 20.0f
#define kScreenWidth ((CGFloat)([UIScreen mainScreen].bounds.size.width))
#define kScreenHeight ((CGFloat)([UIScreen mainScreen].bounds.size.height))

static NSString * const kWAFetchingAnimation = @"WAFetchingAnimation";

@interface WAStatusBar ()

@property (nonatomic, strong) UIImageView *fetchingAnimation;

@end

@implementation WAStatusBar

- (id)initWithFrame:(CGRect)frame {
  
  self = [super initWithFrame:frame];
  if (self) {
    
    self.windowLevel = UIWindowLevelStatusBar + 1.0;
    self.backgroundColor = [UIColor blackColor];
    self.hidden = NO;
    self.opaque = NO;
    
    self.syncingLabel = [[UILabel alloc] init];
    [self.syncingLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.syncingLabel.textColor = [UIColor whiteColor];
    self.syncingLabel.font = [UIFont boldSystemFontOfSize:13.0];
    self.syncingLabel.backgroundColor = [UIColor blackColor];
    [self addSubview:self.syncingLabel];
    
    self.fetchingAnimation = [[UIImageView alloc] init];
    [self.fetchingAnimation setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.fetchingAnimation.image = [[UIImage imageNamed:@"WARefreshGlyph"] irSolidImageWithFillColor:[UIColor whiteColor] shadow:nil];
    [self addSubview:self.fetchingAnimation];

    UILabel *syncingStatus = self.syncingLabel;
    UIImageView *fetchingStatus = self.fetchingAnimation;
    NSDictionary *viewDic = NSDictionaryOfVariableBindings(syncingStatus, fetchingStatus);
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.syncingLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.fetchingAnimation attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[syncingStatus]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:viewDic]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[fetchingStatus(14)]-3-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:viewDic]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[fetchingStatus(14)]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:viewDic]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStatusBarFrame:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    
    [self rotateToStatusBarFrame];
  }
  return self;
  
}

- (void)dealloc {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
}

- (void)rotateToStatusBarFrame {
  
  BOOL visibleBeforeTransformation = YES;
  if (self.alpha == 0) {
    visibleBeforeTransformation = NO;
  } else {
    self.alpha = 0;
  }
  
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  if (orientation == UIDeviceOrientationPortrait) {
    self.transform = CGAffineTransformIdentity;
    self.frame = CGRectMake(kScreenWidth/2-55, 0, kScreenWidth/2+55, kStatusBarHeight);
  } else if (orientation == UIDeviceOrientationLandscapeLeft) {
    self.transform = CGAffineTransformMakeRotation(M_PI_2);
    self.frame = CGRectMake(kScreenWidth-kStatusBarHeight, kScreenHeight/2-55, kStatusBarHeight, kScreenHeight/2+55);
  } else if (orientation == UIDeviceOrientationLandscapeRight) {
    self.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.frame = CGRectMake(0, 0, kStatusBarHeight, kScreenHeight/2+55);
  } else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
    self.transform = CGAffineTransformMakeRotation(M_PI);
    self.frame = CGRectMake(0, kScreenHeight-kStatusBarHeight, kScreenWidth/2+55, kStatusBarHeight);
  }
  
  if (visibleBeforeTransformation) {
    __weak WAStatusBar *wSelf = self;
    [UIView animateWithDuration:0.0f
		      delay:[UIApplication sharedApplication].statusBarOrientationAnimationDuration
		    options:UIViewAnimationOptionTransitionNone
		 animations:^{
		   wSelf.alpha = 1.0;
		 }
		 completion:nil];
  }
  
}

- (void)setIsFetching:(BOOL)isFetching {

  NSParameterAssert([NSThread isMainThread]);

  if (_isFetching != isFetching) {
    _isFetching = isFetching;
    if (_isFetching && ![self.fetchingAnimation.layer animationForKey:kWAFetchingAnimation]) {
      CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
      rotationAnimation.toValue = @(-M_PI);
      rotationAnimation.duration = 1.5;
      rotationAnimation.repeatCount = 0;
      rotationAnimation.delegate = self;
      rotationAnimation.removedOnCompletion = YES;
      [self.fetchingAnimation.layer addAnimation:rotationAnimation forKey:kWAFetchingAnimation];
    }
  }

}

#pragma mark - Core Animation delegates

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {

  NSParameterAssert([NSThread isMainThread]);

  if (self.isFetching) {
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = @(-M_PI);
    rotationAnimation.duration = 1.5;
    rotationAnimation.repeatCount = 0;
    rotationAnimation.delegate = self;
    rotationAnimation.removedOnCompletion = YES;
    [self.fetchingAnimation.layer addAnimation:rotationAnimation forKey:kWAFetchingAnimation];
  }

}

#pragma mark - Target actions

- (void)didChangeStatusBarFrame:(NSNotification *)notification {
  
  [self rotateToStatusBarFrame];
  
}

@end
