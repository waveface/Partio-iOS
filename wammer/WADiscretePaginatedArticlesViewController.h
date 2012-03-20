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

@class WAArticle;
@interface WADiscretePaginatedArticlesViewController : WAArticlesViewController <IRPaginatedViewDelegate, WAPaginationSliderDelegate>

@property (nonatomic, readwrite, retain) IBOutlet WAPaginationSlider *paginationSlider;
@property (retain, nonatomic) IBOutlet IRConcaveView *paginationSliderSlot;
@property (nonatomic, readwrite, retain) IBOutlet IRPaginatedView *paginatedView;

- (void) updateLastReadingProgressAnnotation;

- (NSUInteger) gridIndexOfLastReadArticle;
- (NSUInteger) gridIndexOfArticle:(WAArticle *)anArticle;

- (void) performReadingProgressSync;	//	will transition and stuff
- (void) retrieveLatestReadingProgress;
- (void) retrieveLatestReadingProgressWithCompletion:(void(^)(NSTimeInterval timeTaken))aBlock;
- (void) updateLatestReadingProgressWithIdentifier:(NSString *)anIdentifier;
- (void) updateLatestReadingProgressWithIdentifier:(NSString *)anIdentifier completion:(void(^)(BOOL didUpdate))aBlock;

@property (nonatomic, readonly, retain) NSString *lastReadObjectIdentifier;
@property (nonatomic, readonly, retain) NSString *lastHandledReadObjectIdentifier;
@property (nonatomic, readonly, retain) WAPaginationSliderAnnotation *lastReadingProgressAnnotation;
@property (nonatomic, readonly, retain) UIView *lastReadingProgressAnnotationView;

@end


#import "WADiscretePaginatedArticlesViewController+DiscreteLayout.h"
#import "WADiscretePaginatedArticlesViewController+ContextPresenting.h"
