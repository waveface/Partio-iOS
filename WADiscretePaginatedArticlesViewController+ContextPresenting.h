//
//  WADiscretePaginatedArticlesViewController+ContextPresenting.h
//  wammer
//
//  Created by Evadne Wu on 2/29/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADiscretePaginatedArticlesViewController.h"

@interface WADiscretePaginatedArticlesViewController (ContextPresenting)

- (void) presentDetailedContextForArticle:(NSURL *)anObjectURI;
- (void) presentDetailedContextForArticle:(NSURL *)anObjectURI animated:(BOOL)animated;
- (void) presentDetailedContextForArticle:(NSURL *)anObjectURI usingAnimation:(WAArticleContextAnimation)animation;

@end
