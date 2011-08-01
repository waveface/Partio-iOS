//
//  WAArticleViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/28/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "QuartzCore+IRAdditions.h"
#import "WAArticleViewController.h"
#import "WADataStore.h"
#import "WAImageStackView.h"

@interface WAArticleViewController () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) WAArticle *article;

- (void) refreshView;
- (void) updateLayoutForCommentsVisible:(BOOL)showingDetailedComments;

@end


@implementation WAArticleViewController
@synthesize managedObjectContext, article;
@synthesize contextInfoContainer, mainContentView, avatarView, relativeCreationDateLabel, userNameLabel, articleDescriptionLabel, commentRevealButton, commentPostButton, commentCloseButton, compositionAccessoryView, compositionContentField, compositionSendButton, commentsView, commentsContainerView, commentsRevealingActionContainerView, overlayView, backgroundView;

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
	
	self.commentsRevealingActionContainerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
	self.commentsContainerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;	
	
	
	self.commentsContainerView.layer.shadowOffset = (CGSize){ 0.0f, 1.0f };
	self.commentsContainerView.layer.shadowOpacity = 0.5f;
	self.commentsContainerView.layer.shadowRadius = 4.0f;
	self.commentsContainerView.layer.actions = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNull null], @"shadowPath",
	nil];
	self.commentsRevealingActionContainerView.layer.actions = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNull null], @"shadowPath",
	nil];
	
	self.commentsRevealingActionContainerView.layer.shadowOffset = (CGSize){ 0.0f, 1.0f };
	self.commentsRevealingActionContainerView.layer.shadowOpacity = 0.5f;
	self.commentsRevealingActionContainerView.layer.shadowRadius = 4.0f;

	//	__block __typeof__(self) nrSelf = self;
	__block __typeof__(self.commentsContainerView) nrContainerView = self.commentsContainerView;
	__block __typeof__(self.commentsRevealingActionContainerView) nrRevealingActionContainerView = self.commentsRevealingActionContainerView;
	
	self.commentsContainerView.onPointInsideWithEvent = ^ (CGPoint aPoint, UIEvent *anEvent, BOOL superAnswer) {
	
		CGPoint pointWithinRevealingContainerView = [nrContainerView convertPoint:aPoint toView:nrRevealingActionContainerView];
		
		if ([nrRevealingActionContainerView pointInside:pointWithinRevealingContainerView withEvent:anEvent])
			return YES;
			
		return superAnswer;
	
	};
	
	UIPanGestureRecognizer *panGestureRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCommentViewPan:)] autorelease];
	panGestureRecognizer.delegate = self;
	[self.view addGestureRecognizer:panGestureRecognizer];
	
	[self.commentsContainerView addSubview:self.commentsRevealingActionContainerView];
	[self.commentsContainerView sendSubviewToBack:self.commentsRevealingActionContainerView];
	[self.view addSubview:self.commentsContainerView];
	
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
	
	//	[self.commentsView reloadData]; // Eh?
	
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	CGPathRef oldCommentsContainerShadowPath = self.commentsContainerView.layer.shadowPath;
	CGPathRef oldCommentsRevealingActionContainerShadowPath = self.commentsRevealingActionContainerView.layer.shadowPath;

	if (oldCommentsContainerShadowPath)
		CFRetain(oldCommentsContainerShadowPath);
	
	if (oldCommentsRevealingActionContainerShadowPath)
		CFRetain(oldCommentsRevealingActionContainerShadowPath);
		
	CGRect commentsContainerViewFrame = self.commentsContainerView.frame;
	BOOL commentsContainerVisible = (CGRectGetMinY(commentsContainerViewFrame) >= CGRectGetMinY(self.view.bounds));
	[self updateLayoutForCommentsVisible:commentsContainerVisible];
	
	if (oldCommentsContainerShadowPath) {
		[self.commentsContainerView.layer addAnimation:((^ {
			CABasicAnimation *transition = [CABasicAnimation animationWithKeyPath:@"shadowPath"];
			transition.fromValue = (id)oldCommentsContainerShadowPath;
			transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			transition.duration = duration;
			return transition;
		})()) forKey:@"transition"];
		CFRelease(oldCommentsContainerShadowPath);
	}
	if (oldCommentsRevealingActionContainerShadowPath) {
		[self.commentsRevealingActionContainerView.layer addAnimation:((^ {
			CABasicAnimation *transition = [CABasicAnimation animationWithKeyPath:@"shadowPath"];
			transition.fromValue = (id)oldCommentsRevealingActionContainerShadowPath;
			transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			transition.duration = duration;
			return transition;
		})()) forKey:@"transition"];
		CFRelease(oldCommentsRevealingActionContainerShadowPath);
	}
	
	for (UIView *aView in self.mainContentView.subviews) {
		CGFloat oldShadowOpacity = aView.layer.shadowOpacity;
		aView.layer.shadowOpacity = 0.0f;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * duration), dispatch_get_main_queue(), ^ {
			aView.layer.shadowOpacity = oldShadowOpacity;
		});
	}
	
}





- (BOOL) gestureRecognizer:(UIGestureRecognizer *)panGestureRecognizer shouldReceiveTouch:(UITouch *)touch {

		BOOL hitsCommentView = CGRectContainsPoint(
			UIEdgeInsetsInsetRect(self.commentsRevealingActionContainerView.bounds, (UIEdgeInsets){ -8, -8, -8, -8 }),
			[touch locationInView:self.commentsRevealingActionContainerView]
		);
		
		return hitsCommentView;

}

- (void) handleCommentViewPan:(UIPanGestureRecognizer *)panRecognizer {
	
	static BOOL commentsViewWasShown = NO;
	static CGPoint beginTouch = (CGPoint){ 0, 0 };
	
	CGFloat distance = [panRecognizer locationInView:self.view].y - CGRectGetMinY(self.view.bounds);
	distance = MAX(0, MIN(CGRectGetHeight(self.commentsContainerView.frame), distance));
	
	switch (panRecognizer.state) {
	
		case UIGestureRecognizerStatePossible:
		case UIGestureRecognizerStateBegan: {
		
			commentsViewWasShown = (CGRectGetMaxY(self.commentsContainerView.frame) == CGRectGetHeight(self.commentsContainerView.frame));
			beginTouch = [panRecognizer locationInView:self.view];
		
			break;
		}
		
		case UIGestureRecognizerStateChanged: {
		
			CGPoint newOrigin = (CGPoint){
				CGRectGetMidX(self.view.bounds) - 0.5f * CGRectGetWidth(self.commentsContainerView.frame),
				distance - CGRectGetHeight(self.commentsContainerView.frame)
			};
		
			void (^operations)() = ^ {
				self.commentsContainerView.frame = (CGRect){ newOrigin, self.commentsContainerView.frame.size };
				self.commentsContainerView.layer.shadowOpacity = (distance > 0.0f) ? 0.5f : 0.0f;
			};
		
			if (!commentsViewWasShown && (distance < 64.0f)) {
			
				NSTimeInterval duration = ((distance / 64.0f) * 0.3f);
			
				if (duration > 0.1f)
					[UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:operations completion:nil];
				else
					operations();
			
			} else {
			
				operations();
			
			}
						
			break;
		
		}
		case UIGestureRecognizerStateEnded:
		case UIGestureRecognizerStateCancelled:
		case UIGestureRecognizerStateFailed: {
		
			CGFloat currentCommentsContainerViewHeight = CGRectGetHeight(self.commentsContainerView.frame);
			
			__block CGFloat oldShadowOpacity, newShadowOpacity;
			
			[UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^(void) {
			
				oldShadowOpacity = self.commentsContainerView.layer.shadowOpacity;
			
				if (!commentsViewWasShown && (distance < 0.25f * currentCommentsContainerViewHeight))
					[self updateLayoutForCommentsVisible:NO];
				else if (commentsViewWasShown && (distance < 0.75f * currentCommentsContainerViewHeight))
					[self updateLayoutForCommentsVisible:NO];
				else
					[self updateLayoutForCommentsVisible:YES];
					
				newShadowOpacity = self.commentsContainerView.layer.shadowOpacity;
				self.commentsContainerView.layer.shadowOpacity = oldShadowOpacity;
			
			} completion:^(BOOL finished) {
				
				self.commentsContainerView.layer.shadowOpacity = newShadowOpacity;
				
			}];

			break;
			
		}
	
	};
	
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

	self.commentsRevealingActionContainerView.frame = (CGRect){
		(CGPoint){
			CGRectGetMidX(self.commentsContainerView.bounds) - 0.5f * CGRectGetWidth(self.commentsRevealingActionContainerView.bounds),
			CGRectGetMaxY(self.commentsContainerView.bounds)
		},
		self.commentsRevealingActionContainerView.frame.size
	};
	
	CGSize commentsContainerViewSize = (CGSize){
		768.0f - 32.0f,
		CGRectGetHeight(self.view.bounds) - 96.0f
	};
	
	self.commentsContainerView.frame = (CGRect){
		(CGPoint){
			CGRectGetMidX(self.view.bounds) - 0.5f * commentsContainerViewSize.width,
			(showingDetailedComments ? 0.0f : -1.0f) * commentsContainerViewSize.height
		},
		commentsContainerViewSize
	};
	
	self.commentsContainerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.commentsContainerView.bounds].CGPath;
	self.commentsRevealingActionContainerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.commentsRevealingActionContainerView.bounds].CGPath;
	
	if (showingDetailedComments) {
		
		self.commentPostButton.alpha = 0.0f;
		self.commentPostButton.enabled = NO;
		self.commentRevealButton.alpha = 0.0f;
		self.commentRevealButton.enabled = NO;
		self.commentCloseButton.alpha = 1.0f;
		self.commentCloseButton.enabled = YES;
		self.commentsContainerView.layer.shadowOpacity = 0.5f;
		
		BOOL needsReload = (!self.commentsView.dataSource || !self.commentsView.delegate);
	
		if (!self.commentsView.dataSource)
			self.commentsView.dataSource = self;

		if (!self.commentsView.delegate)
			self.commentsView.delegate = self;

		if (needsReload) {
			NSLog(@"FIXME: Needing Reload");
			//	[self.commentsView reloadData];
		}
		
	} else {
		
		self.commentPostButton.alpha = 1.0f;
		self.commentPostButton.enabled = YES;
		self.commentRevealButton.alpha = 1.0f;
		self.commentRevealButton.enabled = YES;
		self.commentCloseButton.alpha = 0.0f;
		self.commentCloseButton.enabled = NO;
		self.commentsContainerView.layer.shadowOpacity = 0.0f;

	}
	
}





- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	return 0;

}

@end
