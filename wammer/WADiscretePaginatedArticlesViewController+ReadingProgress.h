//
//  WADiscretePaginatedArticlesViewController+ReadingProgress.h
//  wammer
//
//  Created by Evadne Wu on 3/26/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADiscretePaginatedArticlesViewController.h"

@interface WADiscretePaginatedArticlesViewController (ReadingProgress)

- (void) updateLastReadingProgressAnnotation;
- (void) performReadingProgressSync;	//	with (internal) transition

- (void) retrieveLatestReadingProgressWithCompletion:(void(^)(NSTimeInterval timeTaken))aBlock;
- (void) updateLatestReadingProgressWithIdentifier:(NSString *)anIdentifier completion:(void(^)(BOOL didUpdate))aBlock;

- (NSUInteger) gridIndexOfLastReadArticle;

@property (nonatomic, readonly, retain) NSString *lastReadObjectIdentifier;
@property (nonatomic, readonly, retain) NSString *lastHandledReadObjectIdentifier;
@property (nonatomic, readonly, retain) WAPaginationSliderAnnotation *lastReadingProgressAnnotation;
@property (nonatomic, readonly, retain) UIView *lastReadingProgressAnnotationView;

@end
