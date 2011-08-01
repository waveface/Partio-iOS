//
//  WAArticleViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/28/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class WAImageStackView;

@interface WAArticleViewController : UIViewController

+ (WAArticleViewController *) controllerRepresentingArticle:(NSURL *)articleObjectURL;

@property (nonatomic, readwrite, retain) IBOutlet UIView *overlayView;
@property (nonatomic, readwrite, retain) IBOutlet UIView *backgroundView;

@property (nonatomic, readwrite, retain) IBOutlet UIView *contextInfoContainer;
@property (nonatomic, readwrite, retain) IBOutlet WAImageStackView *mainContentView;
@property (nonatomic, readwrite, retain) IBOutlet UIImageView *avatarView;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *relativeCreationDateLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *userNameLabel;
@property (nonatomic, readwrite, retain) IBOutlet UILabel *articleDescriptionLabel;
@property (nonatomic, readwrite, retain) IBOutlet UIButton *commentRevealButton;
@property (nonatomic, readwrite, retain) IBOutlet UIButton *commentPostButton;

@property (nonatomic, readwrite, retain) IBOutlet UIButton *commentCloseButton;
@property (nonatomic, readwrite, retain) IBOutlet UIView *compositionAccessoryView;
@property (nonatomic, readwrite, retain) IBOutlet UITextField *compositionContentField;
@property (nonatomic, readwrite, retain) IBOutlet UIButton *compositionSendButton;

@property (nonatomic, readwrite, retain) IBOutlet UITableView *commentsView;


- (IBAction) handleCommentReveal:(id)sender;
- (IBAction) handleCommentPost:(id)sender;
- (IBAction) handleCommentClose:(id)sender;

@end
