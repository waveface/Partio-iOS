//
//  WAStatusBar.m
//  wammer
//
//  Created by kchiu on 12/11/15.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAStatusBar.h"

#define kStatusBarHeight 20.0f
#define kScreenWidth ((CGFloat)([UIScreen mainScreen].bounds.size.width))
#define kScreenHeight ((CGFloat)([UIScreen mainScreen].bounds.size.height))

@interface WAStatusBar ()

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
    self.syncingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.syncingLabel.textColor = [UIColor whiteColor];
    self.syncingLabel.font = [UIFont boldSystemFontOfSize:13.0];
    self.syncingLabel.backgroundColor = [UIColor blackColor];
    [self addSubview:self.syncingLabel];
    
    self.fetchingLabel = [[UILabel alloc] init];
    self.fetchingLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.fetchingLabel.textColor = [UIColor whiteColor];
    self.fetchingLabel.font = [UIFont boldSystemFontOfSize:13.0];
    self.fetchingLabel.backgroundColor = [UIColor blackColor];
    [self addSubview:self.fetchingLabel];
    
    UILabel *syncingStatus = self.syncingLabel;
    UILabel *fetchingStatus = self.fetchingLabel;
    NSDictionary *viewDic = NSDictionaryOfVariableBindings(syncingStatus, fetchingStatus);
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.syncingLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.fetchingLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[syncingStatus]" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:viewDic]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[fetchingStatus]-5-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:viewDic]];
    
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

#pragma mark - Target actions

- (void)didChangeStatusBarFrame:(NSNotification *)notification {
  
  [self rotateToStatusBarFrame];
  
}

@end
