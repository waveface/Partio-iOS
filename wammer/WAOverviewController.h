//
//  WADiscretePaginatedArticlesViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/31/11.
//  Copyright 2011 Waveface Inc. All rights reserved.
//

#import "WAArticlesViewController.h"
#import "WAPaginationSlider.h"
#import "IRPaginatedView.h"
#import "IRBarButtonItem.h"

@class WAArticle, WAArticleViewController;
@interface WAOverviewController : WAArticlesViewController <IRPaginatedViewDelegate, WAPaginationSliderDelegate>

@property (nonatomic, readwrite, retain) IBOutlet WAPaginationSlider *paginationSlider;
@property (nonatomic, readwrite, retain) IBOutlet IRPaginatedView *paginatedView;

- (NSUInteger) gridIndexOfArticle:(WAArticle *)anArticle;

- (void) enqueueInterfaceUpdate:(void(^)(void))aBlock sender:(WAArticleViewController *)controller;

@end

#import "WAOverviewController+DiscreteLayout.h"
#import "WAOverviewController+ContextPresenting.h"
