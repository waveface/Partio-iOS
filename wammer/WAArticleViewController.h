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

#import "WAView.h"
#import "WAArticleTextEmphasisLabel.h"

#import "WAPreviewBadge.h"

#import "IRAlertView.h"
#import "IRActionSheetController.h"
#import "IRBarButtonItem.h"

#import "WAArticleView.h"


@class WAImageStackView;

@protocol WAArticleViewControllerPresenting
- (void) setContextControlsVisible:(BOOL)contextControlsVisible animated:(BOOL)animated;

@optional
- (void) enqueueInterfaceUpdate:(void(^)(void))anAction;
- (void) handlePreferredInterfaceRect:(CGRect)aRect;

@end


#ifndef __WAArticleViewController__
#define __WAArticleViewController__

enum {

	WAUnknownArticleStyle = -1,

	WAFullFramePlaintextArticleStyle = 0,
	WAFullFrameImageStackArticleStyle,
	WAFullFramePreviewArticleStyle,
  WAFullFrameDocumentArticleStyle,
  
	WADiscretePlaintextArticleStyle,
	WADiscreteSingleImageArticleStyle,
	WADiscretePreviewArticleStyle,
  WADiscreteDocumentArticleStyle
	
}; typedef NSInteger WAArticleViewControllerPresentationStyle;

extern NSString * NSStringFromWAArticleViewControllerPresentationStyle (WAArticleViewControllerPresentationStyle aStyle);
extern WAArticleViewControllerPresentationStyle WAArticleViewControllerPresentationStyleFromString (NSString *aString);

extern WAArticleViewControllerPresentationStyle WAFullFrameArticleStyleFromDiscreteStyle (WAArticleViewControllerPresentationStyle aStyle);
extern WAArticleViewControllerPresentationStyle WADiscreteArticleStyleFromFullFrameStyle (WAArticleViewControllerPresentationStyle aStyle);

#endif

@class WANavigationController;
@interface WAArticleViewController : UIViewController <WAArticleViewControllerPresenting>

+ (WAArticleViewControllerPresentationStyle) suggestedStyleForArticle:(WAArticle *)anArticle DEPRECATED_ATTRIBUTE;
+ (WAArticleViewControllerPresentationStyle) suggestedDiscreteStyleForArticle:(WAArticle *)anArticle;

+ (WAArticleViewController *) controllerForArticle:(NSURL *)articleObjectURL usingPresentationStyle:(WAArticleViewControllerPresentationStyle)aStyle;

@property (nonatomic, readonly, retain) NSURL *representedObjectURI;
@property (nonatomic, readonly, retain) WAArticle *article;

@property (nonatomic, readonly, assign) WAArticleViewControllerPresentationStyle presentationStyle;
@property (nonatomic, readwrite, copy) void (^onViewDidLoad)(WAArticleViewController *self, UIView *loadedView);
@property (nonatomic, readwrite, copy) void (^onViewTap)();
@property (nonatomic, readwrite, copy) void (^onViewPinch)(UIGestureRecognizerState state, CGFloat scale, CGFloat velocity);
@property (nonatomic, readwrite, copy) void (^onPresentingViewController)(void(^action)(UIViewController <WAArticleViewControllerPresenting> *parentViewController));

@property (nonatomic, retain) UIView<WAArticleView> *view;

@property (nonatomic, readwrite, retain) NSArray *additionalDebugActions;

- (WANavigationController *) wrappingNavController;

@end
