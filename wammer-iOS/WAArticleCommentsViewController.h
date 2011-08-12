//
//  WAArticleCommentsViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/2/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "WAView.h"
#import "WAArticleCommentsViewCell.h"


typedef enum {
	WAArticleCommentsViewControllerStateHidden = 0,
	WAArticleCommentsViewControllerStateShown
} WAArticleCommentsViewControllerState;

@class WAArticleCommentsViewController;
@protocol WAArticleCommentsViewControllerDelegate <NSObject>
- (void) articleCommentsViewController:(WAArticleCommentsViewController *)controller wantsState:(WAArticleCommentsViewControllerState)aState onFulfillment:(void(^)(void))aCompletionBlock;
@end


@interface WAArticleCommentsViewController : UIViewController

+ (WAArticleCommentsViewController *) controllerRepresentingArticle:(NSURL *)articleObjectURL;

@property (nonatomic, readwrite, retain) IBOutlet WAView *view;

@property (nonatomic, readwrite, retain) NSURL *representedArticleURI;
@property (nonatomic, readwrite, assign) id<WAArticleCommentsViewControllerDelegate> delegate;
@property (nonatomic, readwrite, assign) WAArticleCommentsViewControllerState state;

@property (nonatomic, readwrite, retain) IBOutlet UITableView *commentsView;
@property (nonatomic, readwrite, retain) IBOutlet UIButton *commentRevealButton;
@property (nonatomic, readwrite, retain) IBOutlet UIButton *commentPostButton;
@property (nonatomic, readwrite, retain) IBOutlet UIButton *commentCloseButton;

@property (nonatomic, readwrite, retain) IBOutlet UITextView *compositionContentField;
@property (nonatomic, readwrite, retain) IBOutlet UIButton *compositionSendButton;

@property (nonatomic, readwrite, retain) IBOutlet WAView *compositionAccessoryView;
@property (nonatomic, readwrite, retain) IBOutlet WAView *commentsRevealingActionContainerView;

- (IBAction) handleCommentReveal:(id)sender;
- (IBAction) handleCommentPost:(id)sender;
- (IBAction) handleCommentClose:(id)sender;

@end
