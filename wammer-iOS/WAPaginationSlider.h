//
//  WAPaginationSlider.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/21/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@class WAPaginationSlider;

@protocol WAPaginationSliderDelegate <NSObject>

- (BOOL) paginationSlider:(WAPaginationSlider *)slider shouldMoveToPage:(NSUInteger)destinationPage;
- (void) paginationSlider:(WAPaginationSlider *)slider didMoveToPage:(NSUInteger)destinationPage;

@end


@interface WAPaginationSlider : UIView

@property (nonatomic, readwrite, assign) CGFloat dotRadius;
@property (nonatomic, readwrite, assign) CGFloat dotMargin;
@property (nonatomic, readwrite, assign) UIEdgeInsets edgeInsets;

@property (nonatomic, readwrite, assign) NSUInteger numberOfPages;
@property (nonatomic, readwrite, assign) BOOL snapsToPages;

@property (nonatomic, readwrite, assign) id<WAPaginationSliderDelegate> delegate;

@end
