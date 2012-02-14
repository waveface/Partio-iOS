//
//  WAStackedArticleViewController.h
//  wammer
//
//  Created by Evadne Wu on 12/22/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAArticleViewController.h"
#import "WAStackView.h"

@class WAArticleTextStackCell, WAArticleTextEmphasisLabel, WAArticleCommentsViewController;

@interface WAStackedArticleViewController : WAArticleViewController <UITableViewDelegate, WAStackViewDelegate>

@property (nonatomic, readwrite, retain) IBOutlet WAStackView *stackView;
@property (nonatomic, readwrite, copy) void (^onViewDidLoad)(WAArticleViewController *self, UIView *ownView); 
@property (nonatomic, readwrite, copy) void (^onPullTop)(UIScrollView *pulledScrollView);

@property (nonatomic, readonly, retain) UIView *footerCell;
@property (nonatomic, readwrite, retain) UIView *headerView;


//	Exposed for subclasses only

@property (nonatomic, readonly, retain) WAArticleTextStackCell *topCell;
@property (nonatomic, readonly, retain) WAArticleTextStackCell *textStackCell;
@property (nonatomic, readonly, retain) WAArticleTextEmphasisLabel *textStackCellLabel;
@property (nonatomic, readonly, retain) WAArticleCommentsViewController *commentsVC;

@end
