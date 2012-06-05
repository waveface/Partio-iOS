//
//  WAOverviewController+ContextPresenting.h
//  wammer
//
//  Created by Evadne Wu on 2/29/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAOverviewController.h"


@class WAArticleViewController;
@interface WAOverviewController (ContextPresenting)

@property (nonatomic, readonly, retain) WAArticle *presentedArticle;

- (WAArticleViewController *) presentDetailedContextForArticle:(WAArticle *)article;
- (void) dismissArticleContextViewController:(WAArticleViewController *)controller;

- (WAArticleViewController *) newContextViewControllerForArticle:(WAArticle *)article;
- (UINavigationController *) wrappingNavigationControllerForContextViewController:(WAArticleViewController *)controller;

@end
