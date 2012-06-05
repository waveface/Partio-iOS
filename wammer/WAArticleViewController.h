//
//  WAArticleViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/28/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>
#import "WAArticleStyle.h"

@class WAArticle, WAArticleView, WAOverviewController;

@protocol WAArticleViewControllerDelegate;

@interface WAArticleViewController : UIViewController

+ (WAArticleViewController *) controllerForArticle:(WAArticle *)article style:(WAArticleStyle)style;

@property (nonatomic, readonly, retain) WAArticle *article;
@property (nonatomic, readonly, assign) WAArticleStyle style;

@property (nonatomic, readwrite, weak) WAOverviewController *hostingViewController;
@property (nonatomic, readwrite, weak) id<WAArticleViewControllerDelegate> delegate;

- (void) reloadData;

@end

@protocol WAArticleViewControllerDelegate <NSObject>

- (NSString *) presentationTemplateNameForArticleViewController:(WAArticleViewController *)controller;

- (void) articleViewControllerDidLoadView:(WAArticleViewController *)controller;
- (void) articleViewController:(WAArticleViewController *)controller didReceiveTap:(UITapGestureRecognizer *)tapGR;
- (void) articleViewController:(WAArticleViewController *)controller didReceivePinch:(UIPinchGestureRecognizer *)pinchGR;

@end
