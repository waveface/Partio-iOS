//
//  WAArticleCommentsViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/2/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAArticleCommentsViewController.h"

#import "CoreData+IRAdditions.h"
#import "QuartzCore+IRAdditions.h"
#import "WADataStore.h"

#import "UIView+WAAdditions.h"
#import "CGGeometry+IRAdditions.h"

@interface WAArticleCommentsViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) WAArticle *article;

- (void) refreshView;

@end


@implementation WAArticleCommentsViewController
@dynamic view;
@synthesize commentsView, commentRevealButton, commentPostButton, commentCloseButton, compositionContentField, compositionSendButton, compositionAccessoryView, commentsRevealingActionContainerView;
@synthesize delegate, state;
@synthesize managedObjectContext, fetchedResultsController, article;

+ (WAArticleCommentsViewController *) controllerRepresentingArticle:(NSURL *)articleObjectURL {

	WAArticleCommentsViewController *returnedController =  [[[self alloc] initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]] autorelease];
	
	returnedController.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	returnedController.representedArticleURI = articleObjectURL;
	
	return returnedController;

}

- (NSURL *) representedArticleURI {

	return [[self.article objectID] URIRepresentation];

}

- (void) setRepresentedArticleURI:(NSURL *)newURI {

	NSParameterAssert(!self.editing);
	
	WAArticle *newArticle = (WAArticle *)[self.managedObjectContext irManagedObjectForURI:newURI];
	
	if ([newArticle isEqual:self.article])
		return;
	
	[self willChangeValueForKey:@"representedArticleURI"];
	self.article = newArticle;
	[self didChangeValueForKey:@"representedArticleURI"];

}





- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	
	if (self.article && !self.fetchedResultsController.fetchedObjects) {
		NSError *fetchingError = nil;
		if (![self.fetchedResultsController performFetch:&fetchingError])
			NSLog(@"Error fetching: %@", fetchingError);
		else
			[self.commentsView reloadData];
	}

}





- (void) viewDidLoad {

	[super viewDidLoad];
	[self.view insertSubview:self.commentsRevealingActionContainerView atIndex:0];
	[self.view addSubview:self.compositionAccessoryView];
	
	__block __typeof__(self.view) nrView = self.view;
	__block __typeof__(self.commentsView) nrCommentsView = self.commentsView;
	__block __typeof__(self.commentsRevealingActionContainerView) nrRevealingActionContainerView = self.commentsRevealingActionContainerView;
	__block __typeof__(self.commentRevealButton) nrCommentRevealButton = self.commentRevealButton;
	__block __typeof__(self.commentCloseButton) nrCommentCloseButton = self.commentCloseButton;
	__block __typeof__(self.compositionAccessoryView) nrCompositionAccessoryView = self.compositionAccessoryView;
	
	self.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;	
	self.view.backgroundColor = [UIColor clearColor];
	self.view.layer.shadowOffset = (CGSize){ 0.0f, 1.0f };
	self.view.layer.shadowOpacity = 0.5f;
	self.view.layer.shadowRadius = 4.0f;
	
	self.commentsView.layer.cornerRadius = 4.0f;
	self.commentsView.layer.masksToBounds = YES;
	self.commentsView.layer.backgroundColor = [UIColor whiteColor].CGColor;
	self.commentsView.contentInset = (UIEdgeInsets){ 20, 0, CGRectGetHeight(self.compositionAccessoryView.frame), 0 };
	self.commentsView.scrollIndicatorInsets = (UIEdgeInsets){ 20, 0, CGRectGetHeight(self.compositionAccessoryView.frame), 0 };
	self.commentsView.frame = UIEdgeInsetsInsetRect(self.commentsView.frame, (UIEdgeInsets){ -20.0f, 0.0f, 0.0f, 0.0f });
	self.commentsView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.commentsView.dataSource = self;
	self.commentsView.delegate = self;
	self.commentsView.rowHeight = 96.0f;
	
	self.commentsRevealingActionContainerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
	self.commentsRevealingActionContainerView.backgroundColor = [UIColor clearColor];
	self.commentsRevealingActionContainerView.layer.shadowOffset = (CGSize){ 0.0f, 1.0f };
	self.commentsRevealingActionContainerView.layer.shadowOpacity = 0.5f;
	self.commentsRevealingActionContainerView.layer.shadowRadius = 4.0f;
	
	self.compositionAccessoryView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
	self.compositionAccessoryView.backgroundColor = [UIColor clearColor];
	self.compositionAccessoryView.opaque = NO;
	
	self.compositionContentField.backgroundColor = [UIColor clearColor];
	self.compositionContentField.scrollIndicatorInsets = (UIEdgeInsets){ 2, 0, 2, 2 };
	
	//	self.compositionAccessoryView.layer.cornerRadius = 4.0f;
	//	self.compositionAccessoryView.layer.masksToBounds = YES;
	
	[self.compositionSendButton setBackgroundImage:[[UIImage imageNamed:@"WACompositionSendButtonBackground"] stretchableImageWithLeftCapWidth:8 topCapHeight:8] forState:UIControlStateNormal];
	
	
	
	UIImageView *textWellBackgroundView = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"WACompositionTextWellBackground"] stretchableImageWithLeftCapWidth:9 topCapHeight:9]] autorelease];
	NSParameterAssert(textWellBackgroundView.image);
	textWellBackgroundView.autoresizingMask = self.compositionContentField.autoresizingMask;
	textWellBackgroundView.frame = UIEdgeInsetsInsetRect(self.compositionContentField.frame, (UIEdgeInsets){ -2, -2, -2, -2 });
	[self.compositionAccessoryView insertSubview:textWellBackgroundView atIndex:0];
	
	UIImageView *backgroundView = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"WACompositionBarBackground"] stretchableImageWithLeftCapWidth:4 topCapHeight:8]] autorelease];
	backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	backgroundView.frame = UIEdgeInsetsInsetRect(self.compositionAccessoryView.bounds, (UIEdgeInsets){ -4, 0, 0, 0 });
	[self.compositionAccessoryView insertSubview:backgroundView atIndex:0];
	
	[self.compositionAccessoryView.superview bringSubviewToFront:self.compositionAccessoryView];
	
	
	self.view.onLayoutSubviews = ^ {
		
		nrView.layer.shadowPath = [UIBezierPath bezierPathWithRect:nrView.bounds].CGPath;
		
		static CGFloat inactiveAccessoryViewHeight = 64.0f;
		static CGFloat activeAccessoryViewHeight = 128.0f;
		
		BOOL accessoryViewActive = !![nrCompositionAccessoryView waFirstResponderInView];
		CGFloat accessoryViewHeight = accessoryViewActive ? activeAccessoryViewHeight : inactiveAccessoryViewHeight;
		
		CGRect accessoryViewFrame, nullRect;
		CGRectDivide(self.view.bounds, &accessoryViewFrame, &nullRect, accessoryViewHeight, CGRectMaxYEdge);
		
		nrCommentsView.contentInset = (UIEdgeInsets){ 20, 0, accessoryViewHeight, 0 };
		nrCommentsView.scrollIndicatorInsets = (UIEdgeInsets){ 20, 0, accessoryViewHeight, 0 };
		
		nrCompositionAccessoryView.frame = accessoryViewFrame;
		
	};
	
	self.view.onPointInsideWithEvent = ^ (CGPoint aPoint, UIEvent *anEvent, BOOL superAnswer) {
		
		CGPoint pointWithinRevealingContainerView = [nrView convertPoint:aPoint toView:nrRevealingActionContainerView];
		if ([nrRevealingActionContainerView pointInside:pointWithinRevealingContainerView withEvent:anEvent])
			return YES;
		else
			return superAnswer;
		
	};
	
	self.commentsRevealingActionContainerView.onLayoutSubviews = ^ {
		
		nrRevealingActionContainerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:nrRevealingActionContainerView.bounds].CGPath;
		
	};
	
	self.commentsRevealingActionContainerView.onPointInsideWithEvent = ^ (CGPoint aPoint, UIEvent *anEvent, BOOL superAnswer) {
		
		if (CGRectContainsPoint(UIEdgeInsetsInsetRect(nrRevealingActionContainerView.bounds, (UIEdgeInsets){ -32, -32, -32, -32 }), aPoint))
			return YES;
		else
			return superAnswer;
			
	};
	
	self.commentsRevealingActionContainerView.onHitTestWithEvent = ^ (CGPoint aPoint, UIEvent *anEvent, UIView *superAnswer) {
		
		if (superAnswer)
			return superAnswer;
		else if (nrCommentRevealButton.enabled)
			return nrCommentRevealButton;
		else if (nrCommentCloseButton.enabled)
			return nrCommentCloseButton;
		else
			return nil;
		
	};
	
	[self.commentsRevealingActionContainerView insertSubview:((^ { 

		UIView *commentsContainerBackgroundView = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
		commentsContainerBackgroundView.backgroundColor = [UIColor clearColor];
		
		[commentsContainerBackgroundView.layer addSublayer:((^ {
			
			CAShapeLayer *maskLayer = [CAShapeLayer layer];
			maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.commentsRevealingActionContainerView.bounds byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight cornerRadii:(CGSize){ 4.0f, 4.0f }].CGPath;
			maskLayer.fillColor = [UIColor whiteColor].CGColor;
			return maskLayer;
		
		})())];
		
		return commentsContainerBackgroundView;
	
	})()) atIndex:0];
	
	self.compositionAccessoryView.frame = (CGRect){
		(CGPoint){
			0,
			CGRectGetHeight(self.view.bounds) - CGRectGetHeight(self.compositionAccessoryView.frame)
		},
		(CGSize){
			CGRectGetWidth(self.view.bounds),
			CGRectGetHeight(self.compositionAccessoryView.frame)	
		}
	};
	
	self.commentsRevealingActionContainerView.frame = (CGRect) {
		(CGPoint){
			roundf(0.5f * (CGRectGetWidth(self.view.bounds) - CGRectGetWidth(self.commentsRevealingActionContainerView.frame))),
			CGRectGetHeight(self.view.bounds)
		},
		self.commentsRevealingActionContainerView.frame.size	
	};
		
	if (self.article)
		[self refreshView];
	
}

- (void) viewDidUnload {

	self.commentsView = nil;
	self.commentRevealButton = nil;
	self.commentPostButton = nil;
	self.commentCloseButton = nil;

	self.compositionContentField = nil;
	self.compositionSendButton = nil;

	self.compositionAccessoryView = nil;
	self.commentsRevealingActionContainerView = nil;

	[super viewDidUnload];

}





- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	CGPathRef oldCommentsContainerShadowPath = self.view.layer.shadowPath;
	CGPathRef oldCommentsRevealingActionContainerShadowPath = self.commentsRevealingActionContainerView.layer.shadowPath;

	if (oldCommentsContainerShadowPath)
		CFRetain(oldCommentsContainerShadowPath);
	
	if (oldCommentsRevealingActionContainerShadowPath)
		CFRetain(oldCommentsRevealingActionContainerShadowPath);
		
	if (oldCommentsContainerShadowPath) {
		[self.view.layer addAnimation:((^ {
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

}

- (void) setState:(WAArticleCommentsViewControllerState)newState {

	if (state != newState) {
		[self willChangeValueForKey:@"state"];
		state = newState;
		[self didChangeValueForKey:@"state"];
	}
	
	switch (state) {
	
		case WAArticleCommentsViewControllerStateShown: {
			
			self.commentPostButton.alpha = 0.0f;
			self.commentPostButton.enabled = NO;
			self.commentRevealButton.alpha = 0.0f;
			self.commentRevealButton.enabled = NO;
			self.commentCloseButton.alpha = 1.0f;
			self.commentCloseButton.enabled = YES;
			self.view.layer.shadowOpacity = 0.5f;
			break;
			
		}
		
		case WAArticleCommentsViewControllerStateHidden: {
			
			self.commentPostButton.alpha = 1.0f;
			self.commentPostButton.enabled = YES;
			self.commentRevealButton.alpha = 1.0f;
			self.commentRevealButton.enabled = YES;
			self.commentCloseButton.alpha = 0.0f;
			self.commentCloseButton.enabled = NO;
			self.view.layer.shadowOpacity = 0.0f;
			break;
			
		}
	
	}
	
	[self refreshView];
	
}





- (void) handleCommentReveal:(id)sender {
	[self.delegate articleCommentsViewController:self wantsState:WAArticleCommentsViewControllerStateShown onFulfillment:nil];
}

- (void) handleCommentClose:(id)sender {
	[self.delegate articleCommentsViewController:self wantsState:WAArticleCommentsViewControllerStateHidden onFulfillment:nil];
}

- (void) handleCommentPost:(id)sender {
	[self.delegate articleCommentsViewController:self wantsState:WAArticleCommentsViewControllerStateShown onFulfillment: ^ {
		[self.compositionContentField becomeFirstResponder];
	}];
}





- (void) setArticle:(WAArticle *)newArticle {

	if (newArticle == article)
		return;
	
	[self willChangeValueForKey:@"article"];
	[article release];
	article = [newArticle retain];
	
	self.fetchedResultsController = nil;
	
	[self didChangeValueForKey:@"article"];
	
	[self refreshView];
	
}

- (void) refreshView {

	[self.commentRevealButton setTitle:[NSString stringWithFormat:@"%x %@", [self.article.comments count], (([self.article.comments count] > 1) ? @"comments" : @"comment")] forState:UIControlStateNormal];
	
	IRCATransact(^ {
		[self.commentsView reloadData];
	});

}





- (NSFetchedResultsController *) fetchedResultsController {

	if (fetchedResultsController)
		return fetchedResultsController;
	
	if (!self.article)
		return nil;
		
	NSFetchRequest *fetchRequest = [self.managedObjectContext.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRCommentsForArticle" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
		self.article, @"Article",
	nil]];
	
	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
		[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO],
	nil];
	
	
	NSLog(@"fetchRequest %@", fetchRequest);
	
	self.fetchedResultsController = [[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil] autorelease];
	
	NSError *fetchingError = nil;
	if (![fetchedResultsController performFetch:&fetchingError])
		NSLog(@"Error fetching: %@", fetchingError);
	
	NSLog(@"Fetched %@", self.fetchedResultsController.fetchedObjects);
	
	return fetchedResultsController;

}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	return [[self.fetchedResultsController fetchedObjects] count];

}

- (UITableViewCell *) tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *cellIdentifier = @"CommentsCell";
	
	WAComment *representedComment = (WAComment *)[self.fetchedResultsController objectAtIndexPath:indexPath];
	
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
	
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
		
		cell.detailTextLabel.numberOfLines = 0;
		cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
	
	}
	
	cell.textLabel.text = [NSString stringWithFormat:@"%@ via %@ at %@", representedComment.owner.nickname, representedComment.creationDeviceName, representedComment.timestamp];
	
	cell.detailTextLabel.text = representedComment.text;
	
	return cell;

}





- (void) textViewDidBeginEditing:(UITextView *)textView {

	[UIView animateWithDuration:0.3f animations: ^ {
		[self.view setNeedsLayout];
		[self.view layoutIfNeeded];
	}];

}

- (void) textViewDidEndEditing:(UITextView *)textView {

	[UIView animateWithDuration:0.3f animations: ^ {
		[self.view setNeedsLayout];
		[self.view layoutIfNeeded];
	}];
	
}

- (void) dealloc {

	[commentsView release];
	[commentRevealButton release];
	[commentPostButton release];
	[commentCloseButton release];
	[compositionContentField release];
	[compositionSendButton release];
	[compositionAccessoryView release];
	[commentsRevealingActionContainerView release];
	
	[managedObjectContext release];
	[fetchedResultsController release];
	[article release];
	
	[super dealloc];

}

@end
