//
//  WANavigationBar.h
//  wammer
//
//  Created by Evadne Wu on 10/4/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WANavigationBar : UINavigationBar

@property (nonatomic, readwrite, retain) UIView *customBackgroundView;
@property (nonatomic, readwrite, assign) BOOL suppressesDefaultAppearance;

+ (UIView *) defaultGradientBackgroundView;
+ (UIView *) defaultPatternBackgroundView;
+ (UIView *) defaultShadowBackgroundView;

@property (nonatomic, readwrite, copy) void (^onBarStyleContextChanged)(void);

@end
