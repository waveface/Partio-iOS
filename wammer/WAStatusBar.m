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

@property (nonatomic, strong) NSArray *constraintsShowingStatusAndProgress;
@property (nonatomic, strong) NSArray *constraintsShowingStatus;

@end

@implementation WAStatusBar

- (id)initWithFrame:(CGRect)frame {
  
  self = [super initWithFrame:frame];
  if (self) {
    
    self.windowLevel = UIWindowLevelStatusBar + 1.0;
    self.backgroundColor = [UIColor blackColor];
    self.hidden = NO;
    self.opaque = NO;
    
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.font = [UIFont boldSystemFontOfSize:13.0];
    self.statusLabel.backgroundColor = [UIColor blackColor];
    [self addSubview:self.statusLabel];
    
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressView.progressTintColor = [UIColor whiteColor];
    self.progressView.trackTintColor = [UIColor blackColor];
    self.progressView.layer.borderWidth = 2.0;
    self.progressView.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.progressView.layer.cornerRadius = 5.0;
    [self addSubview:self.progressView];
    
    UILabel *status = self.statusLabel;
    UIProgressView *progress = self.progressView;
    NSDictionary *viewDic = NSDictionaryOfVariableBindings(status, progress);
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.statusLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:-1]];

    self.constraintsShowingStatusAndProgress = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[status(==20@500)]-[progress(==100)]-5-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:viewDic];
    self.constraintsShowingStatus = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[status(==20@500)]-[progress(==0)]-5-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:viewDic];

    [self addConstraints:self.constraintsShowingStatusAndProgress];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStatusBarFrame:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    
    [self rotateToStatusBarFrame];
  }
  return self;
  
}

- (void)dealloc {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
}

- (void)showStatusOnly {
  
  NSParameterAssert([NSThread isMainThread]);
  
  if (!self.progressView.hidden) {
    
    self.progressView.hidden = YES;
    
    [self removeConstraints:self.constraintsShowingStatusAndProgress];
    [self addConstraints:self.constraintsShowingStatus];
    
    [self updateConstraintsIfNeeded];
    
  }
  
}

- (void)showStatusAndProgress {

  NSParameterAssert([NSThread isMainThread]);

  if (self.progressView.hidden) {

    self.progressView.hidden = NO;

    [self removeConstraints:self.constraintsShowingStatus];
    [self addConstraints:self.constraintsShowingStatusAndProgress];
    
    [self updateConstraintsIfNeeded];

  }

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
    self.frame = CGRectMake(0, 0, kScreenWidth, kStatusBarHeight);
  } else if (orientation == UIDeviceOrientationLandscapeLeft) {
    self.transform = CGAffineTransformMakeRotation(M_PI_2);
    self.frame = CGRectMake(kScreenWidth-kStatusBarHeight, 0, kStatusBarHeight, kScreenHeight);
  } else if (orientation == UIDeviceOrientationLandscapeRight) {
    self.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.frame = CGRectMake(0, 0, kStatusBarHeight, kScreenHeight);
  } else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
    self.transform = CGAffineTransformMakeRotation(M_PI);
    self.frame = CGRectMake(0, kScreenHeight-kStatusBarHeight, kScreenWidth, kStatusBarHeight);
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
