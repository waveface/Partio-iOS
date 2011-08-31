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


@class WAImageStackView;

@protocol WAArticleViewControllerPresenting
- (void) setContextControlsVisible:(BOOL)contextControlsVisible animated:(BOOL)animated;
@end


#ifndef __WAArticleViewController__
#define __WAArticleViewController__

typedef enum {
    
	WAArticleViewControllerPresentationStandalone = 0,
	WAArticleViewControllerPresentationFullFrame,
	WAArticleViewControllerPresentationDefault = WAArticleViewControllerPresentationStandalone
    	
} WAArticleViewControllerPresentationStyle;

#endif

@interface WAArticleViewController : UIViewController

+ (WAArticleViewController *) controllerRepresentingArticle:(NSURL *)articleObjectURL;

@property (nonatomic, readwrite, assign) WAArticleViewControllerPresentationStyle presentationStyle;

@property (nonatomic, readwrite, retain) IBOutlet UIView *contextInfoContainer;
@property (nonatomic, readwrite, retain) IBOutlet WAImageStackView *imageStackView;
@property (nonatomic, readwrite, retain) IBOutlet WAArticleTextEmphasisLabel *textEmphasisView;
@property (nonatomic, readwrite, retain) IBOutlet UIImageView *avatarView;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *relativeCreationDateLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *userNameLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *articleDescriptionLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *deviceDescriptionLabel;

@property (nonatomic, readwrite, copy) void (^onPresentingViewController)(void(^action)(UIViewController <WAArticleViewControllerPresenting> *parentViewController));

- (NSURL *) representedObjectURI;

@end
