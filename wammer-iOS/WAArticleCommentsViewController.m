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

@interface WAArticleCommentsViewController ()

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) WAArticle *article;

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
	
	if (!self.fetchedResultsController.fetchedObjects) {
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





- (NSFetchedResultsController *) fetchedResultsController {

	if (fetchedResultsController)
		return fetchedResultsController;
		
	NSFetchRequest *fetchRequest = [self.managedObjectContext.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRCommentsForArticle" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
		self.article, @"OWNER",
	nil]];
	
	self.fetchedResultsController = [[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil] autorelease];
	
	return fetchedResultsController;

}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	return 200;

}

- (UITableViewCell *) tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *cellIdentifier = @"CommentsCell";
	
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
	
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
	
	}
	
	cell.textLabel.text = [indexPath description];
	
	return cell;

}

- (void) dealloc {

	[managedObjectContext release];
	[fetchedResultsController release];
	[article release];

}

@end
