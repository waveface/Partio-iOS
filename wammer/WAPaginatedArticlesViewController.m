//
//  WAPaginatedArticlesViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WADefines.h"

#import "WADataStore.h"
#import "WAPaginatedArticlesViewController.h"
#import "WAPaginationSlider.h"
#import "WAImageStackView.h"

#import "WARemoteInterface.h"

#import "IRPaginatedView.h"
#import "IRBarButtonItem.h"
#import "IRTransparentToolbar.h"
#import "IRActionSheetController.h"
#import "IRActionSheet.h"
#import "IRAlertView.h"

#import "WAArticleViewController.h"
#import "WAArticleCommentsViewController.h"

#import "UIView+IRAdditions.h"

#import "WADataStore+WARemoteInterfaceAdditions.h"


@interface WAPaginatedArticlesViewController () <IRPaginatedViewDelegate, WAPaginationSliderDelegate, WAArticleCommentsViewControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, readwrite, retain) IRPaginatedView *paginatedView;

@property (nonatomic, readwrite, retain) UIView *coachmarkView;
@property (nonatomic, readwrite, retain) WAPaginationSlider *paginationSlider;
@property (nonatomic, readwrite, retain) NSArray *articleViewControllers;
- (void) refreshPaginatedViewPages;

@property (nonatomic, readwrite, retain) UIButton *articleCommentsDismissalButton;

@property (nonatomic, readwrite, retain) WAArticleCommentsViewController *articleCommentsViewController;
- (BOOL) inferredArticleCommentsVisible;
- (void) updateLayoutForCommentsVisible:(BOOL)showingDetailedComments;

@end


@implementation WAPaginatedArticlesViewController
@synthesize paginatedView;
@synthesize coachmarkView;
@synthesize paginationSlider;
@synthesize articleViewControllers;
@synthesize articleCommentsViewController;
@synthesize articleCommentsDismissalButton;
@synthesize context;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self)
		return nil;
		
	return self;

}

- (void) dealloc {

	[paginatedView removeObserver:self forKeyPath:@"currentPage"];
	
}

- (void) loadView {

	self.view = [[UIView alloc] initWithFrame:(CGRect){ 0, 0, 512, 512 }];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.view.backgroundColor = [UIColor colorWithWhite:0.97f alpha:1.0f];
	
	self.paginatedView = [[IRPaginatedView alloc] initWithFrame:UIEdgeInsetsInsetRect(self.view.bounds, (UIEdgeInsets){ 32, 0, 32, 0 })];
	self.paginatedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.paginatedView.backgroundColor = self.view.backgroundColor;
	self.paginatedView.delegate = self;
	self.paginatedView.horizontalSpacing = 32.0f;
	self.paginatedView.scrollView.clipsToBounds = NO;
	
	self.coachmarkView = [[UIView alloc] initWithFrame:self.view.bounds];
	self.coachmarkView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.coachmarkView.opaque = NO;
	self.coachmarkView.backgroundColor = [UIColor clearColor];
	[self.coachmarkView addSubview:((^ {
	
		UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		spinner.center = (CGPoint){ CGRectGetMidX(self.coachmarkView.bounds), CGRectGetMidY(self.coachmarkView.bounds) };
		spinner.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
		[spinner startAnimating];
		return spinner;
	
	})())];
	
	self.paginationSlider = [[WAPaginationSlider alloc] initWithFrame:(CGRect){ 0, CGRectGetHeight(self.view.frame) - 44, CGRectGetWidth(self.view.frame), 44 }];
	self.paginationSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;	
	self.paginationSlider.delegate = self;
	
	self.articleCommentsDismissalButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.articleCommentsDismissalButton addTarget:self action:@selector(handleArticleContentsDismissal:) forControlEvents:UIControlEventTouchUpInside];
	self.articleCommentsDismissalButton.frame = self.view.bounds;
	self.articleCommentsDismissalButton.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.articleCommentsDismissalButton.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
	self.articleCommentsDismissalButton.alpha = 0;
	self.articleCommentsDismissalButton.enabled = NO;
	
	self.articleCommentsViewController = [WAArticleCommentsViewController controllerRepresentingArticle:nil];
	self.articleCommentsViewController.delegate = self;
	
	[self.view addSubview:self.paginatedView];
	[self.view addSubview:self.coachmarkView];
	[self.view addSubview:self.paginationSlider];
	[self.view addSubview:self.articleCommentsDismissalButton];
	[self.view addSubview:self.articleCommentsViewController.view];

	[self updateLayoutForCommentsVisible:NO];
	
}

- (void) viewDidLoad {

	[super viewDidLoad];
	[self refreshPaginatedViewPages];
	[self updateLayoutForCommentsVisible:NO];
	[self.paginatedView addObserver:self forKeyPath:@"currentPage" options:NSKeyValueObservingOptionNew context:nil];
	
	UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCommentViewPan:)];
	panGestureRecognizer.delegate = self;
	[self.view addGestureRecognizer:panGestureRecognizer];
	
	//	UIPinchGestureRecognizer *pinchRecognizer = [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)] autorelease];
	//	pinchRecognizer.delegate = self;
	//	[self.view addGestureRecognizer:pinchRecognizer];
	
}

- (void) viewDidUnload {

	//	TBD remember current paginated view page

	[self.paginatedView removeObserver:self forKeyPath:@"currentPage"];
	
	self.paginatedView = nil;
	self.coachmarkView = nil;
	self.paginationSlider = nil;
	
	//	Don’t throw them away.
	//	Just keep them.
	//	self.articleViewControllers = nil;
	
	self.articleCommentsDismissalButton = nil;
	self.articleCommentsViewController = nil;
	
	[super viewDidUnload];

}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	
	[self updateLayoutForCommentsVisible:NO];
	[self.articleCommentsViewController.view setNeedsLayout];
	[self.articleCommentsViewController viewWillAppear:animated];
		
	[self setContextControlsVisible:YES animated:NO];
	
	
	NSURL *lastVisitedObjectURI = nil;
	if ((lastVisitedObjectURI = [self.context objectForKey:@"lastVisitedObjectURI"])) {
		
		NSUInteger foundIndex = [self.fetchedResultsController.fetchedObjects indexOfObject:[self.fetchedResultsController.managedObjectContext irManagedObjectForURI:lastVisitedObjectURI]];
		if (foundIndex != NSNotFound) {
			
			//	iOS5b7 bug workaround
			//	Ah, the desperate
			
			[self.paginatedView layoutSubviews];
			[self.paginatedView scrollToPageAtIndex:foundIndex animated:NO];
			[self.paginatedView layoutSubviews];
			[self.paginatedView setNeedsLayout];
			
			if (self.paginatedView.currentPage != foundIndex) {
				NSLog(@"WARNING: Paginated view’s current page stays %i when it shall be %i", self.paginatedView.currentPage, foundIndex);
			}
			
		}
		
	}
	
}

- (void) viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];
	[self.articleCommentsViewController viewDidAppear:animated];

}

- (void) viewWillDisappear:(BOOL)animated {

	self.context = ((^ {
		
		NSMutableDictionary *mutatedContext = [self.context mutableCopy];
		NSURL *objectURL = [[[self.fetchedResultsController.fetchedObjects objectAtIndex:self.paginatedView.currentPage] objectID] URIRepresentation];
		[mutatedContext setObject:objectURL forKey:@"lastVisitedObjectURI"];
		
		return mutatedContext;
		
	})());
	
	[super viewWillDisappear:animated];
	
	[self.articleCommentsViewController viewWillDisappear:animated];

}

- (void) viewDidDisappear:(BOOL)animated {

	[super viewDidDisappear:animated];
	[self.articleCommentsViewController viewDidDisappear:animated];

}

- (void) setContextControlsVisible:(BOOL)contextControlsVisible animated:(BOOL)animated {

	__block void (^noclip)(UIView *) = ^ (UIView *aView) {
		if (aView) {
			aView.clipsToBounds = NO;
			noclip(aView.superview);
		}
	};
	
	noclip(self.view);

	self.navigationController.view.backgroundColor = self.paginatedView.backgroundColor;
	
	if (!contextControlsVisible) {
		self.articleCommentsViewController.commentsView.hidden = YES;
		self.articleCommentsViewController.compositionAccessoryView.hidden = YES;
	}

	[UIView animateWithDuration:(animated ? 0.3f : 0.0f) delay:0.0f options:UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction animations:^(void) {
		
		if (contextControlsVisible) {
			self.navigationController.navigationBar.alpha = 1;
			self.paginationSlider.alpha = 1;
			self.articleCommentsViewController.commentsRevealingActionContainerView.alpha = 1;
			self.articleCommentsViewController.view.alpha = 1;
		} else {
			self.navigationController.navigationBar.alpha = 0.01f;
			self.paginationSlider.alpha = 0.01f;
			self.articleCommentsViewController.commentsRevealingActionContainerView.alpha = 0;
			self.articleCommentsViewController.view.alpha = 0;
		}
		
	} completion: ^ (BOOL finished) {
		
		if (finished && contextControlsVisible) {
			self.articleCommentsViewController.commentsView.hidden = NO;
			self.articleCommentsViewController.compositionAccessoryView.hidden = NO;
		}
		
	}];

}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	if ((object == self.paginatedView) && ([keyPath isEqualToString:@"currentPage"])) {
	
		NSUInteger newPage = [[change objectForKey:NSKeyValueChangeNewKey] unsignedIntValue];
		self.paginationSlider.currentPage = newPage;
		
		NSURL *oldURI = self.articleCommentsViewController.representedArticleURI;
		NSURL *newURI = nil;
		
		@try {
			
			if ([self.fetchedResultsController.fetchedObjects count]) {
				newURI = [[[self.fetchedResultsController.fetchedObjects objectAtIndex:newPage] objectID] URIRepresentation];
			}
			
		} @catch (NSException *exception) {
			NSLog(@"Exception %@", exception);
		}
		
		if (oldURI && [oldURI isEqual:newURI])
			return;
		
		self.articleCommentsViewController.representedArticleURI = newURI;
		[self articleCommentsViewController:self.articleCommentsViewController wantsState:WAArticleCommentsViewControllerStateHidden onFulfillment:nil];
		
		if (!self.articleCommentsViewController.representedArticleURI) {
			self.articleCommentsViewController.view.layer.opacity = 0.85f;
			self.articleCommentsViewController.view.userInteractionEnabled = NO;
		} else {
			self.articleCommentsViewController.view.layer.opacity = 1.0f;
			self.articleCommentsViewController.view.userInteractionEnabled = YES;
		}
	
	}

}

- (NSUInteger) numberOfViewsInPaginatedView:(IRPaginatedView *)paginatedView {

	return [[self.fetchedResultsController fetchedObjects] count];

}

- (UIView *) viewForPaginatedView:(IRPaginatedView *)aPaginatedView atIndex:(NSUInteger)index {

	UIView *returnedView = [self viewControllerForSubviewAtIndex:index inPaginatedView:aPaginatedView].view;
	returnedView.backgroundColor = self.paginatedView.backgroundColor;
	
	return returnedView;

}

- (UIViewController *) viewControllerForSubviewAtIndex:(NSUInteger)index inPaginatedView:(IRPaginatedView *)paginatedView {

	if ([self.articleViewControllers count] < (index + 1))
		return nil;

	return [self.articleViewControllers objectAtIndex:index];

}

- (void) paginationSlider:(WAPaginationSlider *)slider didMoveToPage:(NSUInteger)destinationPage {

	if (self.paginatedView.currentPage == destinationPage)
		return;
	
	//	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	dispatch_async(dispatch_get_main_queue(), ^ {
	
		[CATransaction begin];
		CATransition *transition = [CATransition animation];
		transition.type = kCATransitionMoveIn;
		transition.subtype = (self.paginatedView.currentPage < destinationPage) ? kCATransitionFromRight : kCATransitionFromLeft;
		transition.duration = 0.25f;
		transition.fillMode = kCAFillModeForwards;
		transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		transition.removedOnCompletion = YES;
		
		[self.paginatedView scrollToPageAtIndex:destinationPage animated:NO];
		[self.paginatedView.layer addAnimation:transition forKey:@"transition"];
		
		//	[CATransaction setCompletionBlock: ^ {
		//		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, transition.duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^ {
		//			[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		//		});
		//	}];
		
		[CATransaction commit];
	
	});

}

- (void) handleArticleContentsDismissal:(UIButton *)sender {

	[self articleCommentsViewController:self.articleCommentsViewController wantsState:WAArticleCommentsViewControllerStateHidden onFulfillment:nil];

}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	[self.paginatedView setNeedsLayout];
	
	[[self viewControllerForSubviewAtIndex:self.paginatedView.currentPage inPaginatedView:self.paginatedView] willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	//	Do the update first because we cache the updated shadow path in the net method in the articleCommentsViewController.
	[self updateLayoutForCommentsVisible:[self inferredArticleCommentsVisible]];
	
	[self.articleCommentsViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)newOrientation {

	if ([[UIApplication sharedApplication] isIgnoringInteractionEvents])
		return ([UIApplication sharedApplication].statusBarOrientation == newOrientation);
		//	return (self.interfaceOrientation == newOrientation);
		
	if ([self.articleViewControllers count] > self.paginatedView.currentPage)
	if (((WAArticleViewController *)[self.articleViewControllers objectAtIndex:self.paginatedView.currentPage]).view.imageStackView.gestureProcessingOngoing)
		return (self.interfaceOrientation == newOrientation);
	
	if ([[UIApplication sharedApplication] isIgnoringInteractionEvents])
		return (self.interfaceOrientation == newOrientation);

	return YES;
	
}

- (BOOL) inferredArticleCommentsVisible {

	return (CGRectGetMinY(self.articleCommentsViewController.view.frame) >= 0) && (CGRectGetHeight(self.articleCommentsViewController.view.frame) > 0);

}

- (void) updateLayoutForCommentsVisible:(BOOL)showingDetailedComments {

	CGSize commentsContainerViewSize = (CGSize){
		768.0f - 32.0f,
		roundf(0.33f * CGRectGetHeight(self.view.bounds))
	};
	
	self.articleCommentsViewController.view.frame = (CGRect){
		(CGPoint){
			CGRectGetMidX(self.view.bounds) - 0.5f * commentsContainerViewSize.width,
			(showingDetailedComments ? 0.0f : -1.0f) * commentsContainerViewSize.height
		},
		commentsContainerViewSize
	};
	
	
	self.articleCommentsDismissalButton.alpha = showingDetailedComments ? 1 : 0;
	self.articleCommentsDismissalButton.enabled = showingDetailedComments ? YES : NO;
	
	self.articleCommentsViewController.state = showingDetailedComments ? WAArticleCommentsViewControllerStateShown : WAArticleCommentsViewControllerStateHidden;
	
	
	if (!showingDetailedComments)	
		[[self.articleCommentsViewController.view irFirstResponderInView] resignFirstResponder];
	
}

- (BOOL) articleCommentsViewController:(WAArticleCommentsViewController *)controller canSendComment:(NSString *)commentText {

	return (BOOL)(![[commentText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]);

}

- (void) articleCommentsViewController:(WAArticleCommentsViewController *)controller wantsState:(WAArticleCommentsViewControllerState)aState onFulfillment:(void (^)(void))aCompletionBlock {
	
	BOOL didWriteComment = !([[controller.compositionContentField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]);
	
	void (^operations)() = ^ {
	
		__block CGFloat oldShadowOpacity, newShadowOpacity;
		oldShadowOpacity = self.articleCommentsViewController.view.layer.shadowOpacity;
	
		[UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations: ^ {
		
			switch (aState) {
				
				case WAArticleCommentsViewControllerStateShown: {
					[self updateLayoutForCommentsVisible:YES];
					break;
				}
				
				case WAArticleCommentsViewControllerStateHidden: {
					[self updateLayoutForCommentsVisible:NO];
					controller.compositionContentField.text = nil;
					break;
				}
				
			}
			
			if (aCompletionBlock)
				aCompletionBlock();
			
			newShadowOpacity = self.articleCommentsViewController.view.layer.shadowOpacity;
		
			if (newShadowOpacity == 0.0f) {
			
				//	Only preserve the old shadow opacity if it is going away as soon as the animation runs, otherwise keep it as long as possible
				
				self.articleCommentsViewController.view.layer.shadowOpacity = oldShadowOpacity;
			
			}
			
		} completion: ^ (BOOL didFinish) {
			
			self.articleCommentsViewController.view.layer.shadowOpacity = newShadowOpacity;
		
		}];
		
	};
	
	
	//	Doing these async bounces allow the animation transactions to fully commit without affecting each other
	
	if (!didWriteComment) {
		
		dispatch_async(dispatch_get_main_queue(), operations);
		
	} else {
		
		dispatch_async(dispatch_get_main_queue(), ^ {
			
			[[IRAlertView alertViewWithTitle:@"Clear Comment?" message:@"All text will be removed." cancelAction:[IRAction actionWithTitle:@"Cancel" block:nil] otherActions:[NSArray arrayWithObjects:[IRAction actionWithTitle:@"OK" block: ^ {
				
				dispatch_async(dispatch_get_main_queue(), operations);
				
			}], nil]] show];
		
		});
		
	}
	
}

- (void) articleCommentsViewController:(WAArticleCommentsViewController *)controller didFinishComposingComment:(NSString *)commentText {
	
	WAArticle *currentArticle = [[self.fetchedResultsController fetchedObjects] objectAtIndex:self.paginatedView.currentPage];
	
	[self remoteDataLoadingWillBeginForOperation:@"createComment"];
	
	[[WADataStore defaultStore] addComment:commentText onArticle:[[currentArticle objectID] URIRepresentation] onSuccess:^{

		dispatch_async(dispatch_get_main_queue(), ^ {
		
			@try {
			
				[controller.commentsView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([controller.commentsView numberOfRowsInSection:([controller.commentsView numberOfSections] - 1)] - 1) inSection:([controller.commentsView numberOfSections] - 1)] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
				
			} @catch (NSException *e) {
				
				//	?
				
			}
			
			[self remoteDataLoadingDidEnd];
		
		});
		
	} onFailure: ^ {
		
		[self remoteDataLoadingDidFailWithError:nil];
		
	}];
	
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)panGestureRecognizer shouldReceiveTouch:(UITouch *)touch {

	if (![panGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
		return YES;

	BOOL touchInsideTab = [self.articleCommentsViewController.commentsRevealingActionContainerView pointInside:[touch locationInView:self.articleCommentsViewController.commentsRevealingActionContainerView] withEvent:nil];
	
	BOOL hasRepresentedArticle = (self.articleCommentsViewController.representedArticleURI != nil);
	
	return touchInsideTab && hasRepresentedArticle;

}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {

	return YES;

}

- (void) handleCommentViewPan:(UIPanGestureRecognizer *)panRecognizer {
	
	static BOOL commentsViewWasShown = NO;
	
	UIView *articleCommentsView = articleCommentsViewController.view;
	CGFloat desiredRevealingPortionLength = MAX(0, MIN(CGRectGetHeight(articleCommentsView.frame), ([panRecognizer locationInView:self.view].y - CGRectGetMinY(self.view.bounds))));
	
	switch (panRecognizer.state) {
	
		case UIGestureRecognizerStatePossible:
		case UIGestureRecognizerStateBegan: {
			
			commentsViewWasShown = (CGRectGetMaxY(articleCommentsView.frame) == CGRectGetHeight(articleCommentsView.frame));
			
			break;
			
		}
		
		case UIGestureRecognizerStateChanged: {
			
			static CGFloat minCatchupAnimationDistance = 3.0f;
			static CGFloat maxCatchupAnimationDistance = 64.0f;
			static NSTimeInterval minCatchupAnimationDuration = 0.1f;
			static NSTimeInterval maxCatchupAnimationDuration = 0.3f;
			BOOL animatesCatchup = NO;
			
			CGPoint oldOrigin = articleCommentsView.frame.origin;
			CGPoint newOrigin = (CGPoint){
				CGRectGetMidX(self.view.bounds) - 0.5f * CGRectGetWidth(articleCommentsView.frame),
				desiredRevealingPortionLength - CGRectGetHeight(articleCommentsView.frame)
			};
			
			NSTimeInterval catchupAnimationDuration = ((desiredRevealingPortionLength / maxCatchupAnimationDistance) * maxCatchupAnimationDuration);;
			
			if (!commentsViewWasShown && (desiredRevealingPortionLength <= maxCatchupAnimationDistance))
				if (fabsf(oldOrigin.y - newOrigin.y) >= minCatchupAnimationDistance)
					if (catchupAnimationDuration >= minCatchupAnimationDuration)
						animatesCatchup = YES;
			
			void (^operations)() = ^ {
				articleCommentsView.frame = (CGRect){ newOrigin, articleCommentsView.frame.size };
				articleCommentsView.layer.shadowOpacity = (desiredRevealingPortionLength > 0.0f) ? 0.5f : 0.0f;
			};
			
			if (animatesCatchup) {
				[UIView animateWithDuration:catchupAnimationDuration delay:0.0f options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut animations:operations completion:nil];
			} else {
				operations();
			}
			
			break;
		
		}
		
		case UIGestureRecognizerStateEnded:
		case UIGestureRecognizerStateCancelled:
		case UIGestureRecognizerStateFailed: {
		
			__block CGFloat oldShadowOpacity, newShadowOpacity;
			oldShadowOpacity = articleCommentsView.layer.shadowOpacity;
			
			[UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^(void) {
			
				BOOL commentsShallBeVisible = YES;
				CGFloat commentsViewHeight = CGRectGetHeight(articleCommentsView.frame);
				
				if (!commentsViewWasShown && (desiredRevealingPortionLength < 0.25f * commentsViewHeight))
					commentsShallBeVisible = NO;
				else if (commentsViewWasShown && (desiredRevealingPortionLength < 0.75f * commentsViewHeight))
					commentsShallBeVisible = NO;
				else
					commentsShallBeVisible = YES;
					
				[self updateLayoutForCommentsVisible:commentsShallBeVisible];
				
				newShadowOpacity = articleCommentsView.layer.shadowOpacity;
				articleCommentsView.layer.shadowOpacity = oldShadowOpacity;
					
			} completion: ^ (BOOL didFinish) {
			
				articleCommentsView.layer.shadowOpacity = newShadowOpacity;
			
			}];

			break;
			
		}
	
	};
	
}

- (void) handlePinch:(UIPinchGestureRecognizer *)pinchRecognizer {

	if (pinchRecognizer.state != UIGestureRecognizerStateChanged)
		return;
	
	if (pinchRecognizer.scale <= 0.9)
	if (pinchRecognizer.velocity <= -1)
		((IRBarButtonItem *)self.navigationItem.leftBarButtonItem).block();
	
}





- (void) refreshPaginatedViewPages {

	BOOL later = NO;

	if (self.paginatedView.scrollView.isDragging)
		later = YES;
	else if (self.paginatedView.scrollView.isDecelerating)
		later = YES;
	else if (self.paginatedView.scrollView.isTracking)
		later = YES;
	
	static BOOL alreadyPostponing = NO;
	
	if (later) {
		if (!alreadyPostponing) {
			alreadyPostponing = YES;
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5f * NSEC_PER_SEC), dispatch_get_current_queue(), ^ {
				[self refreshPaginatedViewPages];
				alreadyPostponing = NO;
			});
		}
		return;
	}
	
	//	[self.fetchedResultsController performFetch:nil];
	
	__block __typeof__(self) nrSelf = self;
	
	NSArray *oldArticleViewControllers = [self.articleViewControllers mutableCopy];
	NSArray *oldArticleObjectIDs = [oldArticleViewControllers irMap: ^ (WAArticleViewController *aVC, NSUInteger index, BOOL *stop) {
		return [aVC.article objectID];
	}];
	
	self.articleViewControllers = [[self.fetchedResultsController fetchedObjects] irMap: ^ (WAArticle *article, NSUInteger index, BOOL *stop) {
	
		WAArticleViewController *articleVC = nil;
		NSManagedObjectID *articleID = [article objectID];
		
		if (oldArticleViewControllers) {
			NSUInteger reusableArticleVCIndex = [oldArticleObjectIDs indexOfObject:articleID];
			if (reusableArticleVCIndex != NSNotFound)
				articleVC = [oldArticleViewControllers objectAtIndex:reusableArticleVCIndex];
		}
		
		if (!articleVC) {
			
			NSURL *articleURI = [[article objectID] URIRepresentation];
			
			articleVC = [WAArticleViewController controllerForArticle:articleURI usingPresentationStyle:(
				[article.fileOrder count] ? WAFullFrameImageStackArticleStyle :
				[article.previews count] ? WAFullFramePreviewArticleStyle : 
				WAFullFramePlaintextArticleStyle
			)];

			articleVC.onPresentingViewController = ^ (void(^action)(UIViewController *parentViewController)) {
				if (action)
					action(nrSelf);
			};

		}
			
		
		return articleVC;
		
	}];
		
	
	[self.paginatedView reloadViews];

	//	if ([self.articleViewControllers isEqualToArray:oldArticleViewControllers])
	//		return;
	
	//	NSUInteger lastCurrentPageIndex = self.paginatedView.currentPage;
	NSUInteger lastNumberOfPages = self.paginatedView.numberOfPages;
		
	NSUInteger numberOfFetchedObjects = [[self.fetchedResultsController fetchedObjects] count];
	self.coachmarkView.hidden = (numberOfFetchedObjects > 0);
	self.paginationSlider.hidden = (numberOfFetchedObjects == 0); 
	self.paginationSlider.numberOfPages = numberOfFetchedObjects;
	
	CGRect paginationSliderFrame = self.paginationSlider.frame;
	paginationSliderFrame.size.width = 320.0f;
	//	paginationSliderFrame.size.width = MIN(256, MAX(MIN(192, paginationSliderFrame.size.width), self.paginationSlider.numberOfPages * (self.paginationSlider.dotMargin + self.paginationSlider.dotRadius)));
	
	paginationSliderFrame.origin.x = roundf(0.5f * (CGRectGetWidth(self.paginationSlider.superview.frame) - paginationSliderFrame.size.width));
	self.paginationSlider.frame = paginationSliderFrame;
	self.paginationSlider.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
	
	if (lastNumberOfPages == 0)
	if (self.paginatedView.numberOfPages > 0) {
		[self.paginatedView scrollToPageAtIndex:(self.paginatedView.numberOfPages - 1) animated:NO];
		self.paginationSlider.currentPage = self.paginatedView.currentPage;
	}
	
}

- (void) reloadViewContents {

	[self refreshPaginatedViewPages];

}

@end
