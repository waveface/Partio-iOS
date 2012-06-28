//
//  WAStackedArticleViewController+Favorite.h
//  wammer
//
//  Created by Evadne Wu on 6/28/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAStackedArticleViewController.h"

@interface WAStackedArticleViewController (Favorite)

- (UIBarButtonItem *) newFavoriteToggleItem;
- (void) handleFavoriteToggle:(id)sender;

@end
