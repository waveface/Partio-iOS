//
//  WADiscretePaginatedArticlesViewController+ContextPresenting.h
//  wammer
//
//  Created by Evadne Wu on 2/29/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADiscretePaginatedArticlesViewController.h"


@class WAArticleViewController;
@interface WADiscretePaginatedArticlesViewController (ContextPresenting)

@property (nonatomic, readonly, retain) WAArticle *presentedArticle;

- (WAArticleViewController *) presentDetailedContextForArticle:(NSURL *)anObjectURI;
- (void) dismissArticleContextViewController:(WAArticleViewController *)controller;

- (WAArticleViewController *) newContextViewControllerForArticle:(NSURL *)anObjectURI;
- (UINavigationController *) wrappingNavigationControllerForContextViewController:(WAArticleViewController *)controller;

@end
