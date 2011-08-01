//
//  WAArticleViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/28/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAArticleViewController.h"
#import "WADataStore.h"

#import "WAImageStackView.h"

@interface WAArticleViewController ()

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) WAArticle *article;

- (void) refreshView;
- (void) updateLayoutForCommentsVisible:(BOOL)showingDetailedComments;

@end


@implementation WAArticleViewController
@synthesize managedObjectContext, article;
@synthesize contextInfoContainer, mainContentView, avatarView, relativeCreationDateLabel, userNameLabel, articleDescriptionLabel, commentRevealButton, commentPostButton, commentCloseButton, compositionAccessoryView, compositionContentField, compositionSendButton, commentsView, overlayView, backgroundView;

+ (WAArticleViewController *) controllerRepresentingArticle:(NSURL *)articleObjectURL {

	WAArticleViewController *returnedController = [[[self alloc] initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]] autorelease];
	
	returnedController.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	returnedController.article = (WAArticle *)[returnedController.managedObjectContext irManagedObjectForURI:articleObjectURL];
	
	return returnedController;

}

- (void) dealloc {

	[managedObjectContext release];
	[article release];
	[super dealloc];

}

- (void) viewDidLoad {

	[super viewDidLoad];
	[self refreshView];
	[self updateLayoutForCommentsVisible:NO];

}

- (void) setArticle:(WAArticle *)newArticle {

	if (article == newArticle)
		return;
	
	[self willChangeValueForKey:@"article"];
	[article release];
	article = [newArticle retain];
	[self didChangeValueForKey:@"article"];
	
	if ([self isViewLoaded])
		[self refreshView];

}

- (void) refreshView {

	self.userNameLabel.text = self.article.owner.nickname;
	self.relativeCreationDateLabel.text = [self.article.timestamp description];
	self.articleDescriptionLabel.text = self.article.text;
	self.mainContentView.files = self.article.files;
	self.avatarView.image = self.article.owner.avatar;
	
	if (!self.userNameLabel.text)
		self.userNameLabel.text = @"A Certain User";
	
	[self.commentsView reloadData]; // Eh?
	
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	//	Unfortunately, when using shadowPath with shouldRasterize

	for (UIView *aView in self.mainContentView.subviews) {
		CGFloat oldShadowOpacity = aView.layer.shadowOpacity;
		aView.layer.shadowOpacity = 0.0f;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * duration), dispatch_get_main_queue(), ^ {
			aView.layer.shadowOpacity = oldShadowOpacity;
		});
	}

}





- (void) handleCommentReveal:(id)sender {
	dispatch_async(dispatch_get_main_queue(), ^ {
		[UIView animateWithDuration:0.3f animations: ^ {
			[self updateLayoutForCommentsVisible:YES];
		}];
	});
}

- (void) handleCommentClose:(id)sender {
	dispatch_async(dispatch_get_main_queue(), ^ {
		[UIView animateWithDuration:0.3f animations: ^ {
			[self updateLayoutForCommentsVisible:NO];
		}];	
	});
}

- (void) handleCommentPost:(id)sender {
	dispatch_async(dispatch_get_main_queue(), ^ {
		[UIView animateWithDuration:0.3f animations: ^ {
			[self updateLayoutForCommentsVisible:YES];
		}];
	});
}

- (void) updateLayoutForCommentsVisible:(BOOL)showingDetailedComments {
	
	if (showingDetailedComments) {
		
		self.commentPostButton.alpha = 0.0f;
		self.commentPostButton.enabled = NO;
		self.commentRevealButton.alpha = 0.0f;
		self.commentRevealButton.enabled = NO;
		self.commentCloseButton.alpha = 1.0f;
		self.commentCloseButton.enabled = YES;
		
		self.mainContentView.alpha = 0.0f;
		self.articleDescriptionLabel.alpha = 0.0f;
		
	} else {
		
		self.commentPostButton.alpha = 1.0f;
		self.commentPostButton.enabled = YES;
		self.commentRevealButton.alpha = 1.0f;
		self.commentRevealButton.enabled = YES;
		self.commentCloseButton.alpha = 0.0f;
		self.commentCloseButton.enabled = NO;
		
		self.mainContentView.alpha = 1.0f;
		self.articleDescriptionLabel.alpha = 1.0f;
		
	}
	
}

@end
