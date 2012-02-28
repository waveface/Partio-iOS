//
//  WADiscretePaginatedArticlesViewController+ContextPresenting.h
//  wammer
//
//  Created by Evadne Wu on 2/29/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADiscretePaginatedArticlesViewController.h"

@protocol WAArticleViewControllerPresenting;
@interface WADiscretePaginatedArticlesViewController (ContextPresenting)

- (UIViewController<WAArticleViewControllerPresenting> *) presentDetailedContextForArticle:(NSURL *)anObjectURI;
- (UIViewController<WAArticleViewControllerPresenting> *) presentDetailedContextForArticle:(NSURL *)anObjectURI animated:(BOOL)animated;
- (UIViewController<WAArticleViewControllerPresenting> *) presentDetailedContextForArticle:(NSURL *)anObjectURI usingAnimation:(WAArticleContextAnimation)animation;

@end
