//
//  WAArticleCommentsViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/2/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAArticleCommentsViewController.h"

#import "CoreData+IRAdditions.h"
#import "WADataStore.h"

@interface WAArticleCommentsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) WAArticle *article;

- (void) refreshView;

@end


@implementation WAArticleCommentsViewController
@synthesize commentsView, commentRevealButton, commentPostButton, commentCloseButton, compositionContentField, compositionSendButton, compositionAccessoryView, commentsContainerView, commentsRevealingActionContainerView;
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
	
	self.commentsRevealingActionContainerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
	self.commentsContainerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;	
	
	self.commentsView.layer.cornerRadius = 4.0f;
	self.commentsView.layer.masksToBounds = YES;
	self.commentsView.layer.backgroundColor = [UIColor whiteColor].CGColor;
	self.commentsView.contentInset = (UIEdgeInsets){ 20, 0, 0, 0 };
	self.commentsView.scrollIndicatorInsets = (UIEdgeInsets){ 20, 0, 0, 0 };
	self.commentsView.frame = UIEdgeInsetsInsetRect(self.commentsView.frame, (UIEdgeInsets){ -20, 0, 0, 0 });
	
	self.commentsContainerView.backgroundColor = [UIColor clearColor];
	self.commentsRevealingActionContainerView.backgroundColor = [UIColor clearColor];
	
	self.commentsContainerView.layer.shadowOffset = (CGSize){ 0.0f, 1.0f };
	self.commentsContainerView.layer.shadowOpacity = 0.5f;
	self.commentsContainerView.layer.shadowRadius = 4.0f;
	
	UIView *commentsContainerBackgroundView = [[[UIView alloc] initWithFrame:self.commentsContainerView.bounds] autorelease];
	commentsContainerBackgroundView.backgroundColor = [UIColor clearColor];
	
	CAShapeLayer *maskLayer = [CAShapeLayer layer];
	maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.commentsRevealingActionContainerView.bounds byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight cornerRadii:(CGSize){ 4.0f, 4.0f }].CGPath;
	maskLayer.fillColor = [UIColor whiteColor].CGColor;

	[commentsContainerBackgroundView.layer addSublayer:maskLayer];
	[self.commentsRevealingActionContainerView addSubview:commentsContainerBackgroundView];
	[self.commentsRevealingActionContainerView sendSubviewToBack:commentsContainerBackgroundView];
	
	self.commentsRevealingActionContainerView.layer.shadowOffset = (CGSize){ 0.0f, 1.0f };
	self.commentsRevealingActionContainerView.layer.shadowOpacity = 0.5f;
	self.commentsRevealingActionContainerView.layer.shadowRadius = 4.0f;

	__block __typeof__(self.commentsContainerView) nrContainerView = self.commentsContainerView;
	__block __typeof__(self.commentsRevealingActionContainerView) nrRevealingActionContainerView = self.commentsRevealingActionContainerView;
	
	nrContainerView.onPointInsideWithEvent = ^ (CGPoint aPoint, UIEvent *anEvent, BOOL superAnswer) {
	
		CGPoint pointWithinRevealingContainerView = [nrContainerView convertPoint:aPoint toView:nrRevealingActionContainerView];
		
		if ([nrRevealingActionContainerView pointInside:pointWithinRevealingContainerView withEvent:anEvent])
			return YES;
			
		return superAnswer;
	
	};
	
	[self.commentsContainerView addSubview:self.commentsRevealingActionContainerView];
	[self.commentsContainerView sendSubviewToBack:self.commentsRevealingActionContainerView];
	
	nrContainerView.onLayoutSubviews = ^ {
		nrContainerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:nrContainerView.bounds].CGPath;
	};

	nrRevealingActionContainerView.onLayoutSubviews = ^ {
		nrRevealingActionContainerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:nrRevealingActionContainerView.bounds].CGPath;
	};
	
	self.commentsRevealingActionContainerView.frame = (CGRect) {
		(CGPoint){
			roundf(0.5f * (CGRectGetWidth(self.commentsContainerView.bounds) - CGRectGetWidth(self.commentsRevealingActionContainerView.frame))),
			CGRectGetHeight(self.commentsContainerView.bounds)
		},
		self.commentsRevealingActionContainerView.frame.size	
	};
	
	
	self.commentsView.dataSource = self;
	self.commentsView.delegate = self;
	self.commentsView.rowHeight = 96.0f;
	
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
	self.commentsContainerView = nil;
	self.commentsRevealingActionContainerView = nil;

	[super viewDidUnload];

}





- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	CGPathRef oldCommentsContainerShadowPath = self.commentsContainerView.layer.shadowPath;
	CGPathRef oldCommentsRevealingActionContainerShadowPath = self.commentsRevealingActionContainerView.layer.shadowPath;

	if (oldCommentsContainerShadowPath)
		CFRetain(oldCommentsContainerShadowPath);
	
	if (oldCommentsRevealingActionContainerShadowPath)
		CFRetain(oldCommentsRevealingActionContainerShadowPath);
		
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
			self.commentsContainerView.layer.shadowOpacity = 0.5f;
			break;
			
		}
		
		case WAArticleCommentsViewControllerStateHidden: {
			
			self.commentPostButton.alpha = 1.0f;
			self.commentPostButton.enabled = YES;
			self.commentRevealButton.alpha = 1.0f;
			self.commentRevealButton.enabled = YES;
			self.commentCloseButton.alpha = 0.0f;
			self.commentCloseButton.enabled = NO;
			self.commentsContainerView.layer.shadowOpacity = 0.0f;
			break;
			
		}
	
	}
	
	
	[self refreshView];
	
}





- (void) handleCommentReveal:(id)sender {
	[self.delegate articleCommentsViewController:self wantsState:WAArticleCommentsViewControllerStateShown];
}

- (void) handleCommentClose:(id)sender {
	[self.delegate articleCommentsViewController:self wantsState:WAArticleCommentsViewControllerStateHidden];
}

- (void) handleCommentPost:(id)sender {
	[self.delegate articleCommentsViewController:self wantsState:WAArticleCommentsViewControllerStateHidden];
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
	
	[self.commentsView reloadData];

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

- (void) dealloc {

	[commentsView release];
	[commentRevealButton release];
	[commentPostButton release];
	[commentCloseButton release];
	[compositionContentField release];
	[compositionSendButton release];
	[compositionAccessoryView release];
	[commentsContainerView release];
	[commentsRevealingActionContainerView release];
	
	[managedObjectContext release];
	[fetchedResultsController release];
	[article release];
	
	[super dealloc];

}

@end
