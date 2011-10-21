//
//  WAPaginatedArticlesViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAArticlesViewController.h"
#import "WAArticleViewController.h"

@interface WAPaginatedArticlesViewController : WAArticlesViewController <WAArticleViewControllerPresenting>

@property (nonatomic, readwrite, retain) NSDictionary *context;

@end
