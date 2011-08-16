//
//  WAArticleViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/28/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>

#import "WAView.h"
@class WAImageStackView;

@interface WAArticleViewController : UIViewController

+ (WAArticleViewController *) controllerRepresentingArticle:(NSURL *)articleObjectURL;

@property (nonatomic, readwrite, retain) IBOutlet UIView *contextInfoContainer;
@property (nonatomic, readwrite, retain) IBOutlet WAImageStackView *imageStackView;
@property (nonatomic, readwrite, retain) IBOutlet UIImageView *avatarView;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *relativeCreationDateLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *userNameLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *articleDescriptionLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *deviceDescriptionLabel;

@property (nonatomic, readwrite, copy) void (^onPresentingViewController)(void(^action)(UIViewController *parentViewController));

@end
