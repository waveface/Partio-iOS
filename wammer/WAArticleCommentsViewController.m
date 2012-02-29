//
//  WAArticleCommentsViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/2/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAArticleCommentsViewController.h"

#import "CoreData+IRAdditions.h"
#import "QuartzCore+IRAdditions.h"
#import "WADataStore.h"

#import "UIKit+IRAdditions.h"
#import "CGGeometry+IRAdditions.h"
#import "WARemoteInterface.h"

@interface WAArticleCommentsViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) WAArticle *article;

@property (nonatomic, readwrite, retain) WAArticleCommentsViewCell *cellPrototype;
@property (nonatomic, readwrite, retain) WAView *compositionAccessoryTextWellBackgroundView;
@property (nonatomic, readwrite, retain) WAView *compositionAccessoryBackgroundView;

- (void) refreshView;

@end


@implementation WAArticleCommentsViewController
@synthesize wrapperView;
@dynamic view;
@synthesize commentsView, commentRevealButton, commentPostButton, commentCloseButton, compositionContentField, compositionSendButton, compositionAccessoryView, commentsRevealingActionContainerView;
@synthesize compositionAccessoryTextWellBackgroundView, compositionAccessoryBackgroundView;
@synthesize delegate, state;
@synthesize managedObjectContext, fetchedResultsController, article;
@synthesize cellPrototype;
@synthesize onViewDidLoad;
@synthesize scrollsToLastRowOnChange, adjustsContainerViewOnInterfaceBoundsChange;
@synthesize coachmarkOverlay;

+ (WAArticleCommentsViewController *) controllerRepresentingArticle:(NSURL *)articleObjectURL {

	WAArticleCommentsViewController *returnedController =  [[[self alloc] initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]] autorelease];
	
	returnedController.managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
	returnedController.representedArticleURI = articleObjectURL;
	
	return returnedController;

}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (!self)
		return nil;
	
	scrollsToLastRowOnChange = YES;
	adjustsContainerViewOnInterfaceBoundsChange = YES;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterfaceBoundsDidChange:) name:IRWindowInterfaceBoundsDidChangeNotification object:nil];
	
	return self;

}

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[commentsView removeObserver:self forKeyPath:@"contentSize"];

	[commentsView release];
	[commentRevealButton release];
	[commentPostButton release];
	[commentCloseButton release];
	[compositionContentField release];
	[compositionSendButton release];
	[compositionAccessoryView release];
	[commentsRevealingActionContainerView release];
	
	[cellPrototype release];
	
	[managedObjectContext release];
	[fetchedResultsController release];
	[article release];
	
	[onViewDidLoad release];
	
	[coachmarkOverlay release];
	
	[wrapperView release];
	[super dealloc];

}

- (NSURL *) representedArticleURI {

	return [[self.article objectID] URIRepresentation];

}

- (void) setRepresentedArticleURI:(NSURL *)newURI {

	NSParameterAssert(!self.editing);
	
	WAArticle *newArticle = newURI ? (WAArticle *)[self.managedObjectContext irManagedObjectForURI:newURI] : nil;
	
	if ([newArticle isEqual:self.article])
		return;
	
	[self willChangeValueForKey:@"representedArticleURI"];
	self.article = newArticle;
	[self didChangeValueForKey:@"representedArticleURI"];

}

- (void) handleInterfaceBoundsDidChange:(NSNotification *)notification {

	if (![self isViewLoaded])
		return;

	if ([notification object] != self.view.window)
		return;

	if (!self.adjustsContainerViewOnInterfaceBoundsChange)
		return;

	[self adjustWrapperViewBoundsWithWindowInterfaceBounds:self.view.window.irInterfaceBounds animated:([[[[[notification userInfo] objectForKey:IRWindowInterfaceChangeUnderlyingKeyboardNotificationKey] userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue] > 0)];

}

- (void) adjustWrapperViewBoundsWithWindowInterfaceBounds:(CGRect)newInterfaceBounds animated:(BOOL)animate {

	if (![self isViewLoaded])
		return;

	if (!self.view.window) {
		self.wrapperView.frame = self.view.bounds;
		return;
	}

	CGRect ownRectInWindow = [self.view.window convertRect:self.view.bounds fromView:self.view];
	CGRect intersection = CGRectIntersection(ownRectInWindow, newInterfaceBounds);
	
	if (CGRectEqualToRect(CGRectNull, intersection) || CGRectIsInfinite(intersection))
		return;
	
	intersection = [self.view.window convertRect:intersection toView:self.wrapperView.superview];
	
	UIViewAnimationOptions animationOptions = UIViewAnimationOptionBeginFromCurrentState;
	
	[UIView animateWithDuration:(animate ? 0.3 : 0) delay:0 options:animationOptions animations:^{
		
		self.wrapperView.frame = intersection;
		
	} completion:^(BOOL finished) {
				
	}];

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
	
	[self adjustWrapperViewBoundsWithWindowInterfaceBounds:self.view.window.irInterfaceBounds animated:NO];

}

- (void) viewWillDisappear:(BOOL)animated {

	[super viewWillDisappear:animated];
	
	[[self.view irFirstResponderInView] resignFirstResponder];

}





- (void) viewDidLoad {

	[super viewDidLoad];
	
	[self.wrapperView insertSubview:self.commentsRevealingActionContainerView atIndex:0];
	[self.wrapperView addSubview:self.compositionAccessoryView];
	
	__block __typeof__(self) nrSelf = self;
	__block __typeof__(self.view) nrView = self.view;
	__block __typeof__(self.commentsView) nrCommentsView = self.commentsView;
	__block __typeof__(self.commentsRevealingActionContainerView) nrRevealingActionContainerView = self.commentsRevealingActionContainerView;
	__block __typeof__(self.commentRevealButton) nrCommentRevealButton = self.commentRevealButton;
	__block __typeof__(self.commentCloseButton) nrCommentCloseButton = self.commentCloseButton;
	__block __typeof__(self.compositionAccessoryView) nrCompositionAccessoryView = self.compositionAccessoryView;
	
	self.view.onSizeThatFits = ^ (CGSize proposedSize, CGSize superAnswer) {
	
		return (CGSize){
			nrSelf.commentsView.contentSize.width,
			MAX(128, MAX(48, nrSelf.commentsView.contentSize.height) + CGRectGetHeight(nrCompositionAccessoryView.bounds))
		};
	
	};
	
	self.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;	
	self.view.backgroundColor = [UIColor clearColor];
	self.view.layer.shadowOffset = (CGSize){ 0.0f, 1.0f };
	self.view.layer.shadowOpacity = 0.25f;
	self.view.layer.shadowRadius = 2.0f;
	
	self.commentsView.layer.cornerRadius = 4.0f;
	self.commentsView.layer.masksToBounds = YES;

#if 0
	self.commentsView.layer.backgroundColor = [UIColor whiteColor].CGColor;
	self.commentsView.contentInset = (UIEdgeInsets){ 20, 0, CGRectGetHeight(self.compositionAccessoryView.frame), 0 };
	self.commentsView.scrollIndicatorInsets = (UIEdgeInsets){ 20, 0, CGRectGetHeight(self.compositionAccessoryView.frame), 0 };
	self.commentsView.frame = UIEdgeInsetsInsetRect(self.commentsView.frame, (UIEdgeInsets){ -20, 0, 0, 0 };
#endif	
	
	self.commentsView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.commentsView.dataSource = self;
	self.commentsView.delegate = self;
	self.commentsView.rowHeight = 96.0f;
	
	self.commentsView.bounces = YES;
	self.commentsView.alwaysBounceVertical = YES;
	 
	self.commentsRevealingActionContainerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
	self.commentsRevealingActionContainerView.backgroundColor = [UIColor clearColor];
	self.commentsRevealingActionContainerView.layer.shadowOffset = (CGSize){ 0.0f, 1.0f };
	self.commentsRevealingActionContainerView.layer.shadowOpacity = 0.25f;
	self.commentsRevealingActionContainerView.layer.shadowRadius = 2.0f;
	
	self.compositionAccessoryView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
	self.compositionAccessoryView.backgroundColor = [UIColor clearColor];
	self.compositionAccessoryView.opaque = NO;
	
	self.compositionContentField.backgroundColor = [UIColor clearColor];
	self.compositionContentField.scrollIndicatorInsets = (UIEdgeInsets){ 2, 0, 2, 2 };
	
	[self.compositionSendButton setBackgroundImage:[[UIImage imageNamed:@"WACompositionSendButtonBackground"] stretchableImageWithLeftCapWidth:8 topCapHeight:8] forState:UIControlStateNormal];
	
	
	
	UIImageView *textWellBackgroundView = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"WACompositionTextWellBackground"] stretchableImageWithLeftCapWidth:14 topCapHeight:14]] autorelease];
	NSParameterAssert(textWellBackgroundView.image);
	textWellBackgroundView.autoresizingMask = self.compositionContentField.autoresizingMask;
	textWellBackgroundView.frame = UIEdgeInsetsInsetRect(self.compositionContentField.frame, (UIEdgeInsets){ 0, -2, -2, -2 });
	[self.compositionAccessoryView insertSubview:textWellBackgroundView atIndex:0];
		
	UIImageView *backgroundView = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"WACompositionBarBackground"] stretchableImageWithLeftCapWidth:4 topCapHeight:8]] autorelease];
	backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	backgroundView.frame = UIEdgeInsetsInsetRect(self.compositionAccessoryView.bounds, (UIEdgeInsets){ -4, 0, 0, 0 });
	
	self.compositionAccessoryTextWellBackgroundView = [[[WAView alloc] initWithFrame:textWellBackgroundView.bounds] autorelease];
	self.compositionAccessoryTextWellBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.compositionAccessoryTextWellBackgroundView addSubview:textWellBackgroundView];
	[self.compositionAccessoryView insertSubview:textWellBackgroundView atIndex:0];
	
	self.compositionAccessoryBackgroundView = [[[WAView alloc] initWithFrame:backgroundView.bounds] autorelease];
	self.compositionAccessoryBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	[self.compositionAccessoryBackgroundView addSubview:backgroundView];
	[self.compositionAccessoryView insertSubview:compositionAccessoryBackgroundView atIndex:0];
	
	[self.compositionAccessoryView.superview bringSubviewToFront:self.compositionAccessoryView];
	
	
	self.view.onLayoutSubviews = ^ {
		
		//	nrView.layer.shadowPath = [UIBezierPath bezierPathWithRect:nrView.bounds].CGPath;
		
		static CGFloat inactiveAccessoryViewHeight = 64.0f;
		static CGFloat activeAccessoryViewHeight = 128.0f;
		
		BOOL accessoryViewActive = !![nrCompositionAccessoryView irFirstResponderInView];
		CGFloat accessoryViewHeight = accessoryViewActive ? activeAccessoryViewHeight : inactiveAccessoryViewHeight;
		
		CGRect accessoryViewFrame, nullRect;
		CGRectDivide(nrSelf.wrapperView.bounds, &accessoryViewFrame, &nullRect, accessoryViewHeight, CGRectMaxYEdge);
		
		UIEdgeInsets commentsViewContentInset = nrCommentsView.contentInset;
		commentsViewContentInset.bottom = accessoryViewHeight;
		
		UIEdgeInsets commentsViewScrollIndicatorInsets = nrCommentsView.scrollIndicatorInsets;
		commentsViewScrollIndicatorInsets.bottom = accessoryViewHeight;
		
		nrCommentsView.contentInset = commentsViewContentInset;
		nrCommentsView.scrollIndicatorInsets = commentsViewScrollIndicatorInsets;
		
		accessoryViewFrame.origin.x = nrCompositionAccessoryView.frame.origin.x;
		accessoryViewFrame.size.width = nrCompositionAccessoryView.frame.size.width;
		
		if (nrView.bounds.size.height == 0) {
			
			//	OMG, this case happens when the app launches in landscape.  Since the text field does not have flexible top / bottom margins, a zero enclosing superview height makes the text field taller than the enclosing superview, and subsequent restoration of the height won’t help anyway: the metrics were already destructed. x_x
			
			CGFloat newHeight = MIN(activeAccessoryViewHeight, MAX(inactiveAccessoryViewHeight, accessoryViewFrame.size.height));
			//	OFFSET origin.y ?
			
			accessoryViewFrame.size.height = newHeight;
			
		}
		
		nrCompositionAccessoryView.frame = accessoryViewFrame;
		
		if (nrSelf.coachmarkOverlay) {
		
			if (![nrSelf.fetchedResultsController.fetchedObjects count]) {
			
				nrSelf.coachmarkOverlay.frame = UIEdgeInsetsInsetRect(
					[nrSelf.view convertRect:nrSelf.commentsView.frame fromView:nrSelf.commentsView.superview],
					commentsViewContentInset
				);
				
				if (nrSelf.coachmarkOverlay.superview != nrSelf.view)
					[nrSelf.view addSubview:nrSelf.coachmarkOverlay];
				else
					[nrSelf.view bringSubviewToFront:nrSelf.coachmarkOverlay];
			
			} else {
			
				[nrSelf.coachmarkOverlay removeFromSuperview];
			
			}
		
		}
				
	};
	
	self.view.onPointInsideWithEvent = ^ (CGPoint aPoint, UIEvent *anEvent, BOOL superAnswer) {
	
		if (superAnswer)
			return superAnswer;
		
		CGPoint pointWithinRevealingContainerView = [nrView convertPoint:aPoint toView:nrRevealingActionContainerView];
		if ([nrRevealingActionContainerView pointInside:pointWithinRevealingContainerView withEvent:anEvent])
			return YES;
		else
			return superAnswer;
		
	};
	
	self.view.onHitTestWithEvent = ^ (CGPoint aPoint, UIEvent *anEvent, UIView *superAnswer) {
	
		if ((superAnswer == nrSelf.commentsView) || ([superAnswer isDescendantOfView:nrSelf.commentsView]))
			return superAnswer;
	
		UIView *hitSubview = [nrRevealingActionContainerView hitTest:aPoint withEvent:anEvent];
		
		if (hitSubview)
			return hitSubview;
		else
			return (UIView *)superAnswer;
	
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
	
		if (nrCommentRevealButton.enabled)
		if (CGRectContainsPoint(UIEdgeInsetsInsetRect(nrCommentRevealButton.frame, (UIEdgeInsets){ -22.0f, -22.0f, -22.0f, -22.0f }), aPoint))
				return (UIView *)nrCommentRevealButton;
		
		if (nrCommentCloseButton.enabled)
		if (CGRectContainsPoint(UIEdgeInsetsInsetRect(nrCommentCloseButton.frame, (UIEdgeInsets){ -22.0f, -22.0f, -22.0f, -22.0f }), aPoint))
				return (UIView *)nrCommentCloseButton;
		
		if (superAnswer)
			return (UIView *)superAnswer;
			
		return (UIView *)nil;
		
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
			self.compositionAccessoryView.frame.origin.x,
			CGRectGetHeight(self.wrapperView.bounds) - CGRectGetHeight(self.compositionAccessoryView.frame)
		},
		(CGSize){
			CGRectGetWidth(self.wrapperView.bounds),
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
	
	[self.commentsView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
	
	if (self.onViewDidLoad)
		self.onViewDidLoad();
	
}

- (void) viewDidUnload {

	[self.commentsView removeObserver:self forKeyPath:@"contentSize"];
	
	self.wrapperView = nil;

	self.commentsView = nil;
	self.commentRevealButton = nil;
	self.commentPostButton = nil;
	self.commentCloseButton = nil;

	self.compositionContentField = nil;
	self.compositionSendButton = nil;

	self.compositionAccessoryView = nil;
	self.commentsRevealingActionContainerView = nil;
	self.cellPrototype = nil;
	
	self.compositionAccessoryTextWellBackgroundView = nil;
	self.compositionAccessoryBackgroundView = nil;
	
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
	
	if (![self.delegate articleCommentsViewController:self canSendComment:self.compositionContentField.text])
		return;
	
	[self.delegate articleCommentsViewController:self didFinishComposingComment:self.compositionContentField.text];
	
	self.compositionContentField.text = nil;
	
	[self.delegate articleCommentsViewController:self wantsState:WAArticleCommentsViewControllerStateShown onFulfillment: ^ {
		[self.compositionContentField resignFirstResponder];
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

	[self.commentRevealButton setTitle:[NSString stringWithFormat:@"%i %@", [self.article.comments count], (([self.article.comments count] > 1) ? @"comments" : @"comment")] forState:UIControlStateNormal];
	
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
		[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES],
	nil];
	
	self.fetchedResultsController = [[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil] autorelease];
	
	self.fetchedResultsController.delegate = self;
	
	NSError *fetchingError = nil;
	if (![fetchedResultsController performFetch:&fetchingError])
		NSLog(@"Error fetching: %@", fetchingError);
	
	return fetchedResultsController;

}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {

	[self.commentsView reloadData];
	
	if (![controller.sections count])
		return;
	
	NSIndexPath *lastObjectIndexPath = [NSIndexPath indexPathForRow:([(id<NSFetchedResultsSectionInfo>)[controller.sections lastObject] numberOfObjects] - 1) inSection:([controller.sections count] - 1)];
	
	if (self.scrollsToLastRowOnChange)
		[self.commentsView scrollToRowAtIndexPath:lastObjectIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];

}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	return [[self.fetchedResultsController fetchedObjects] count];

}

- (WAArticleCommentsViewCell *) cellPrototype {
	
	if (cellPrototype)
		return cellPrototype;
	
	self.cellPrototype = [[[WAArticleCommentsViewCell alloc] initWithCommentsViewCellStyle:WAArticleCommentsViewCellStyleDefault reuseIdentifier:nil] autorelease];
	
	return cellPrototype;
	
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	self.cellPrototype.frame = (CGRect){
		CGPointZero,
		(CGSize){
			CGRectGetWidth(tableView.bounds),
			tableView.rowHeight
		}
	};
	
	CGRect oldFrame = self.cellPrototype.contentTextLabel.frame;
	CGFloat oldHeight = CGRectGetHeight(oldFrame);
	
	self.cellPrototype.contentTextLabel.text = ((WAComment *)[self.fetchedResultsController objectAtIndexPath:indexPath]).text;
	[self.cellPrototype.contentTextLabel sizeToFit];
	
	CGRect newFrame = self.cellPrototype.contentTextLabel.frame;
	CGFloat newHeight = CGRectGetHeight(newFrame);
	
	CGFloat cellHeight = CGRectGetHeight(cellPrototype.frame) + (newHeight - oldHeight);
	self.cellPrototype.contentTextLabel.frame = oldFrame;
	
	return cellHeight;

}

- (UITableViewCell *) tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *cellIdentifier = @"CommentsCell";
	
	WAComment *representedComment = (WAComment *)[self.fetchedResultsController objectAtIndexPath:indexPath];
	
	WAArticleCommentsViewCell *cell = (WAArticleCommentsViewCell *)[aTableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[[WAArticleCommentsViewCell alloc] initWithCommentsViewCellStyle:WAArticleCommentsViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	cell.userNicknameLabel.text = representedComment.owner.nickname;
	cell.avatarView.image = representedComment.owner.avatar;
	cell.contentTextLabel.text = representedComment.text;
	cell.dateLabel.text = [[IRRelativeDateFormatter sharedFormatter] stringFromDate:representedComment.timestamp];
	cell.originLabel.text = representedComment.creationDeviceName;
	
	return cell;

}





- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	if (object == self.commentsView)
	if ([keyPath isEqualToString:@"contentSize"]) {

		CGSize oldSize = [[change objectForKey:NSKeyValueChangeOldKey] CGSizeValue];	
		CGSize newSize = [[change objectForKey:NSKeyValueChangeNewKey] CGSizeValue];
		
		if (CGSizeEqualToSize(oldSize, newSize))
			return;
		
		if ([self.delegate respondsToSelector:@selector(articleCommentsViewController:didChangeContentSize:)])
			[self.delegate articleCommentsViewController:self didChangeContentSize:newSize];
	
	}

}





- (void) textViewDidBeginEditing:(UITextView *)textView {

	[UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations: ^ {
		
		[self.view layoutSubviews];

		if ([self.delegate respondsToSelector:@selector(articleCommentsViewControllerDidBeginComposition:)])
			[self.delegate articleCommentsViewControllerDidBeginComposition:self];
		
	} completion:^(BOOL finished) {
		
	}];
	
}

- (void) textViewDidEndEditing:(UITextView *)textView {

	[UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations: ^ {
		
		[self.view layoutSubviews];
		
		if ([self.delegate respondsToSelector:@selector(articleCommentsViewControllerDidFinishComposition:)])
			[self.delegate articleCommentsViewControllerDidFinishComposition:self];

	} completion:^(BOOL finished) {
		
	}];
		
}

- (CGRect) rectForComposition {

	return [self.view convertRect:self.compositionAccessoryView.frame fromView:self.view];

}

@end
