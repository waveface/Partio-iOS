//
//  WADiscretePaginatedArticlesViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/31/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAArticlesViewController.h"
#import "WAPaginationSlider.h"
#import "IRPaginatedView.h"
#import "IRBarButtonItem.h"

@interface WADiscretePaginatedArticlesViewController : WAArticlesViewController <IRPaginatedViewDelegate, WAPaginationSliderDelegate>

@property (nonatomic, readwrite, retain) IBOutlet WAPaginationSlider *paginationSlider;
@property (nonatomic, readwrite, retain) IBOutlet IRPaginatedView *paginatedView;

@end
