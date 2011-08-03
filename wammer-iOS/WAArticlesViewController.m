//
//  WAArticlesViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WADataStore.h"
#import "WAArticlesViewController.h"
#import "WACompositionViewController.h"
#import "WAPaginationSlider.h"

#import "WARemoteInterface.h"

#import "IRPaginatedView.h"
#import "IRBarButtonItem.h"
#import "IRTransparentToolbar.h"
#import "IRActionSheetController.h"
#import "IRActionSheet.h"

#import "WAArticleViewController.h"
#import "WAArticleCommentsViewController.h"

#import "UIView+WAAdditions.h"


@interface WAArticlesViewController () <IRPaginatedViewDelegate, WAPaginationSliderDelegate, NSFetchedResultsControllerDelegate, WAArticleCommentsViewControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, readwrite, retain) IRPaginatedView *paginatedView;
@property (nonatomic, readwrite, retain) IRActionSheetController *debugActionSheetController;
@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, readwrite, retain) UIView *coachmarkView;
@property (nonatomic, readwrite, retain) WAPaginationSlider *paginationSlider;

@property (nonatomic, readwrite, retain) NSArray *articleViewControllers;
- (void) refreshData;
- (void) refreshPaginatedViewPages;

@property (nonatomic, readwrite, retain) WAArticleCommentsViewController *articleCommentsViewController;
- (BOOL) inferredArticleCommentsVisible;
- (void) updateLayoutForCommentsVisible:(BOOL)showingDetailedComments;

@end


@implementation WAArticlesViewController
@synthesize paginatedView;
@synthesize fetchedResultsController;
@synthesize managedObjectContext;
@synthesize coachmarkView;
@synthesize paginationSlider;
@synthesize debugActionSheetController;
@synthesize articleViewControllers;
@synthesize articleCommentsViewController;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self)
		return nil;
		
	IRTransparentToolbar *toolbar = [[[IRTransparentToolbar alloc] initWithFrame:(CGRect){ 0, 0, 100, 44 }] autorelease];
	toolbar.usesCustomLayout = NO;
	toolbar.items = [NSArray arrayWithObjects:
		[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(handleAction:)] autorelease],
		[IRBarButtonItem itemWithCustomView:[[[UIView alloc] initWithFrame:(CGRect){ 0, 0, 14.0f, 44 }] autorelease]],
		[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(handleCompose:)] autorelease],
		[IRBarButtonItem itemWithCustomView:[[[UIView alloc] initWithFrame:(CGRect){ 0, 0, 8.0f, 44 }] autorelease]],
	nil];
	self.navigationItem.rightBarButtonItem = [IRBarButtonItem itemWithCustomView:toolbar];
	
	self.title = @"Articles";
	
	self.debugActionSheetController = [IRActionSheetController actionSheetControllerWithTitle:nil cancelAction:nil destructiveAction:nil otherActions:[NSArray arrayWithObjects:
	
		[IRAction actionWithTitle:@"Debug Import" block:^(void) {
		
			[[[[UIAlertView alloc] initWithTitle:@"Debug Import" message:@"I should import stuff, but you should not have to relaunch the app to see them anyway." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease] show];
		
		}],
	
	nil]];
		
	self.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:((^ {
	
		NSFetchRequest *returnedRequest = [[[NSFetchRequest alloc] init] autorelease];
		returnedRequest.entity = [NSEntityDescription entityForName:@"WAArticle" inManagedObjectContext:self.managedObjectContext];
		returnedRequest.predicate = [NSPredicate predicateWithFormat:@"ANY files.identifier != nil"]; // TBD files.thumbnailFilePath != nil
		returnedRequest.sortDescriptors = [NSArray arrayWithObjects:
			[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES],
		nil];
		
		return returnedRequest;
	
	})()) managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	
	self.fetchedResultsController.delegate = self;
		
	return self;

}

- (void) dealloc {
	
	[paginatedView release];
	[paginationSlider release];
	[coachmarkView release];
	[managedObjectContext release];
	[fetchedResultsController release];
	[articleCommentsViewController release];
	[super dealloc];

}

- (void) loadView {

	self.view = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.view.backgroundColor = [UIColor colorWithWhite:0.97f alpha:1.0f];
	
	self.paginatedView = [[[IRPaginatedView alloc] initWithFrame:self.view.bounds] autorelease];
	self.paginatedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.paginatedView.backgroundColor = self.view.backgroundColor;
	self.paginatedView.delegate = self;
	
	self.coachmarkView = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
	self.coachmarkView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.coachmarkView.opaque = NO;
	self.coachmarkView.backgroundColor = [UIColor clearColor];
	[self.coachmarkView addSubview:((^ {
	
		UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
		spinner.center = (CGPoint){ CGRectGetMidX(self.coachmarkView.bounds), CGRectGetMidY(self.coachmarkView.bounds) };
		spinner.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
		[spinner startAnimating];
		return spinner;
	
	})())];
	
	
	self.paginationSlider = [[[WAPaginationSlider alloc] initWithFrame:(CGRect){ 0, CGRectGetHeight(self.view.frame) - 44, CGRectGetWidth(self.view.frame), 44 }] autorelease];
	self.paginationSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;	
	self.paginationSlider.delegate = self;
	
	[self.view addSubview:self.paginatedView];
	[self.view addSubview:self.coachmarkView];
	[self.view addSubview:self.paginationSlider];
	
	self.articleCommentsViewController = [WAArticleCommentsViewController controllerRepresentingArticle:nil];
	self.articleCommentsViewController.delegate = self;
	[self.view addSubview:self.articleCommentsViewController.view];
	
	[self updateLayoutForCommentsVisible:NO];
	
}

- (void) viewDidLoad {

	[super viewDidLoad];
	[self refreshPaginatedViewPages];
	[self refreshData];
	[self updateLayoutForCommentsVisible:NO];
	[self.paginatedView addObserver:self forKeyPath:@"currentPage" options:NSKeyValueObservingOptionNew context:nil];
	
	UIPanGestureRecognizer *panGestureRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCommentViewPan:)] autorelease];
	panGestureRecognizer.delegate = self;
	[self.view addGestureRecognizer:panGestureRecognizer];

}

- (void) viewDidUnload {

	[self.paginatedView removeObserver:self forKeyPath:@"currentPage"];
	
	self.paginatedView = nil;
	self.coachmarkView = nil;
	self.paginationSlider = nil;
	
	[super viewDidUnload];

}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	
	[self updateLayoutForCommentsVisible:NO];
	[self.articleCommentsViewController viewWillAppear:animated];

}

- (void) viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];
	[self.articleCommentsViewController viewDidAppear:animated];

}

- (void) viewWillDisappear:(BOOL)animated {

	[super viewWillDisappear:animated];
	
	if (self.debugActionSheetController.managedActionSheet.visible)
		[self.debugActionSheetController.managedActionSheet dismissWithClickedButtonIndex:self.debugActionSheetController.managedActionSheet.cancelButtonIndex animated:animated];
		
	[self.articleCommentsViewController viewWillDisappear:animated];

}

- (void) viewDidDisappear:(BOOL)animated {

	[super viewDidDisappear:animated];
	[self.articleCommentsViewController viewDidDisappear:animated];

}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	if ((object == self.paginatedView) && ([keyPath isEqualToString:@"currentPage"])) {
	
		NSUInteger newPage = [[change objectForKey:NSKeyValueChangeNewKey] unsignedIntValue];
		self.paginationSlider.currentPage = newPage;
		
		NSURL *oldURI = self.articleCommentsViewController.representedArticleURI;
		NSURL *newURI = nil;
		
		@try {
			newURI = [[[self.fetchedResultsController.fetchedObjects objectAtIndex:newPage] objectID] URIRepresentation];
		} @catch (NSException *exception) { /* NO OP */ }
		
		if (oldURI && [oldURI isEqual:newURI])
			return;
		
		self.articleCommentsViewController.representedArticleURI = newURI;
		[self articleCommentsViewController:self.articleCommentsViewController wantsState:WAArticleCommentsViewControllerStateHidden onFulfillment:nil];
	
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

	@try {
		return [self.articleViewControllers objectAtIndex:index];
	} @catch (NSException *e) {
		//	
	}
	
	return nil;

}

- (void) paginationSlider:(WAPaginationSlider *)slider didMoveToPage:(NSUInteger)destinationPage {

	//	NSLog(@"%s %@ %i", __PRETTY_FUNCTION__, slider, destinationPage);
	
	if (self.paginatedView.currentPage == destinationPage)
		return;
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
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
		
		[CATransaction setCompletionBlock: ^ {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, transition.duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^ {
				[[UIApplication sharedApplication] endIgnoringInteractionEvents];
			});
		}];
		
		[CATransaction commit];
	
	});

}

- (void) handleAction:(UIBarButtonItem *)sender {

	[self.debugActionSheetController.managedActionSheet showFromBarButtonItem:sender animated:YES];

}

- (void) handleCompose:(UIBarButtonItem *)sender {

	WACompositionViewController *compositionVC = [[[WACompositionViewController alloc] init] autorelease];
	
	UINavigationController *wrapperNC = [[[UINavigationController alloc] initWithRootViewController:compositionVC] autorelease];
	wrapperNC.modalPresentationStyle = UIModalPresentationFullScreen;
	
	[(self.navigationController ? self.navigationController : self) presentModalViewController:wrapperNC animated:YES];

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
	
			
	self.articleCommentsViewController.state = showingDetailedComments ? WAArticleCommentsViewControllerStateShown : WAArticleCommentsViewControllerStateHidden;
	
	
	if (!showingDetailedComments)	
		[[self.articleCommentsViewController.view waFirstResponderInView] resignFirstResponder];
	
}

- (void) articleCommentsViewController:(WAArticleCommentsViewController *)controller wantsState:(WAArticleCommentsViewControllerState)aState onFulfillment:(void (^)(void))aCompletionBlock {

	dispatch_async(dispatch_get_main_queue(), ^ {
	
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
		
	});

}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)panGestureRecognizer shouldReceiveTouch:(UITouch *)touch {

	return [self.articleCommentsViewController.commentsRevealingActionContainerView pointInside:[touch locationInView:self.articleCommentsViewController.commentsRevealingActionContainerView] withEvent:nil];

}

- (void) handleCommentViewPan:(UIPanGestureRecognizer *)panRecognizer {
	
	static BOOL commentsViewWasShown = NO;
	static CGPoint beginTouch = (CGPoint){ 0, 0 };
	
	CGFloat distance = [panRecognizer locationInView:self.view].y - CGRectGetMinY(self.view.bounds);
	distance = MAX(0, MIN(CGRectGetHeight(self.articleCommentsViewController.view.frame), distance));
	
	switch (panRecognizer.state) {
	
		case UIGestureRecognizerStatePossible:
		case UIGestureRecognizerStateBegan: {
		
			commentsViewWasShown = (CGRectGetMaxY(self.articleCommentsViewController.view.frame) == CGRectGetHeight(self.articleCommentsViewController.view.frame));
			beginTouch = [panRecognizer locationInView:self.view];
		
			break;
		}
		
		case UIGestureRecognizerStateChanged: {
		
			CGPoint newOrigin = (CGPoint){
				CGRectGetMidX(self.view.bounds) - 0.5f * CGRectGetWidth(self.articleCommentsViewController.view.frame),
				distance - CGRectGetHeight(self.articleCommentsViewController.view.frame)
			};
		
			void (^operations)() = ^ {
				self.articleCommentsViewController.view.frame = (CGRect){ newOrigin, self.articleCommentsViewController.view.frame.size };
				self.articleCommentsViewController.view.layer.shadowOpacity = (distance > 0.0f) ? 0.5f : 0.0f;
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
		
			CGFloat currentCommentsContainerViewHeight = CGRectGetHeight(self.articleCommentsViewController.view.frame);
			
			__block CGFloat oldShadowOpacity, newShadowOpacity;
			oldShadowOpacity = self.articleCommentsViewController.view.layer.shadowOpacity;
			
			[UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^(void) {
			
				if (!commentsViewWasShown && (distance < 0.25f * currentCommentsContainerViewHeight))
					[self updateLayoutForCommentsVisible:NO];
				else if (commentsViewWasShown && (distance < 0.75f * currentCommentsContainerViewHeight))
					[self updateLayoutForCommentsVisible:NO];
				else
					[self updateLayoutForCommentsVisible:YES];
				
				newShadowOpacity = self.articleCommentsViewController.view.layer.shadowOpacity;
				
				self.articleCommentsViewController.view.layer.shadowOpacity = oldShadowOpacity;
					
			} completion: ^ (BOOL didFinish) {
			
				self.articleCommentsViewController.view.layer.shadowOpacity = newShadowOpacity;
			
			}];

			break;
			
		}
	
	};
	
}





- (void) refreshPaginatedViewPages {

	[self.fetchedResultsController performFetch:nil];
	
	self.articleViewControllers = [[self.fetchedResultsController fetchedObjects] irMap: ^ (WAArticle *article, int index, BOOL *stop) {

		return [WAArticleViewController controllerRepresentingArticle:[[article objectID] URIRepresentation]];
		
	}];
	
	[self.paginatedView reloadViews];
	
	NSUInteger numberOfFetchedObjects = [[self.fetchedResultsController fetchedObjects] count];
	self.coachmarkView.hidden = (numberOfFetchedObjects > 0);
	self.paginationSlider.hidden = (numberOfFetchedObjects == 0); 
	self.paginationSlider.numberOfPages = numberOfFetchedObjects;
	
	CGRect paginationSliderFrame = self.paginationSlider.frame;
	paginationSliderFrame.size.width = MIN(256, MAX(MIN(192, paginationSliderFrame.size.width), self.paginationSlider.numberOfPages * (self.paginationSlider.dotMargin + self.paginationSlider.dotRadius)));
	
	paginationSliderFrame.origin.x = roundf(0.5f * (CGRectGetWidth(self.paginationSlider.superview.frame) - paginationSliderFrame.size.width));
	self.paginationSlider.frame = paginationSliderFrame;
	self.paginationSlider.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;

}

- (void) refreshData {

	[[WARemoteInterface sharedInterface] retrieveArticlesWithContinuation:nil batchLimit:200 onSuccess:^(NSArray *retrievedArticleReps) {
	
		NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
		
		[WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:retrievedArticleReps usingMapping:[NSDictionary dictionaryWithObjectsAndKeys:
			@"WAFile", @"files",
			@"WAComment", @"comments",
		nil] options:0];
		
		NSError *savingError = nil;
		if (![context save:&savingError])
			NSLog(@"Saving Error %@", savingError);
			
		dispatch_async(dispatch_get_main_queue(), ^ {
			[self refreshPaginatedViewPages];
		});
		
	} onFailure:^(NSError *error) {
		
		NSLog(@"Fail %@", error);
		
	}];

}

- (void) controllerWillChangeContent:(NSFetchedResultsController *)controller {
	
	NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, [NSThread currentThread], controller);
	
}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
	
	NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, [NSThread currentThread], controller);
	
}

@end
