//
//  WADiscretePaginatedArticlesViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/31/11.
//  Copyright 2011 Waveface Inc. All rights reserved.
//

#import <math.h>
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

#import "WAOverviewController.h"
#import "IRDiscreteLayout.h"

#import "WADataStore.h"
#import "WAArticleViewController.h"
#import "WAOverlayBezel.h"

#import "UIKit+IRAdditions.h"
#import "CALayer+IRAdditions.h"

#import "WAFauxRootNavigationController.h"
#import "WANavigationBar.h"

#import "WARemoteInterface.h"
#import "WADataStore.h"
#import "WAArticle+WARemoteInterfaceEntitySyncing.h"

#import "WAGestureWindow.h"
#import "WAButton.h"

#import "WAArticle+DiscreteLayoutAdditions.h"


static NSString * const kWADiscreteArticlePageElements = @"kWADiscreteArticlePageElements";


@interface WAOverviewController () <IRDiscreteLayoutManagerDelegate, IRDiscreteLayoutManagerDataSource, UIGestureRecognizerDelegate, WAPaginationSliderDelegate>

@property (nonatomic, readwrite, retain) IRDiscreteLayoutManager *discreteLayoutManager;
@property (nonatomic, readwrite, retain) IRDiscreteLayoutResult *discreteLayoutResult;
@property (nonatomic, readwrite, retain) NSArray *layoutGrids;
@property (nonatomic, readwrite, assign) BOOL requiresRecalculationOnFetchedResultsChangeEnd;

- (void) adjustPageViewAtIndex:(NSUInteger)anIndex;
- (void) adjustPageView:(UIView *)aPageView usingGridAtIndex:(NSUInteger)anIndex;
- (void) adjustPageView:(UIView *)aPageView withGrid:(IRDiscreteLayoutGrid *)grid;	//	Will use the best transformation destination for the grid with matching aspect ratio of current application frame

- (CGFloat) currentAspectRatio;

@end


@implementation WAOverviewController
@synthesize paginationSlider, discreteLayoutManager, discreteLayoutResult, layoutGrids, paginatedView;
@synthesize requiresRecalculationOnFetchedResultsChangeEnd;

- (void) viewDidLayoutSubviews {

	[super viewDidLayoutSubviews];
	
	if (!self.paginatedView.numberOfPages)
		return;
	
	NSUInteger currentPage = self.paginatedView.currentPage;
	UIView *pageView = [self.paginatedView existingPageAtIndex:currentPage];
	[self adjustPageView:pageView usingGridAtIndex:currentPage];

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	self.view.backgroundColor = [UIColor colorWithRed:242.0/256.0 green:242.0/256.0 blue:242.0/256.0 alpha:1];
	self.view.opaque = YES;
	
	__weak IRPaginatedView *nrPaginatedView = self.paginatedView;
	self.paginatedView.backgroundColor = nil;
	self.paginatedView.horizontalSpacing = 4.0f;
	self.paginatedView.clipsToBounds = NO;
	self.paginatedView.scrollView.clipsToBounds = NO;
	self.paginatedView.onPointInsideWithEvent = ^ (CGPoint aPoint, UIEvent *anEvent, BOOL superAnswer) {
	
		CGPoint convertedPoint = [nrPaginatedView.scrollView convertPoint:aPoint fromView:nrPaginatedView];
		if ([nrPaginatedView.scrollView pointInside:convertedPoint withEvent:anEvent])
			return YES;
		
		return superAnswer;
	
	};
	
	if (self.discreteLayoutResult)
		[self.paginatedView reloadViews];
	
	self.paginationSlider.dotMargin = 32;
	self.paginationSlider.edgeInsets = (UIEdgeInsets){ 0, 16, 0, 16 };
	self.paginationSlider.backgroundColor = nil;
	self.paginationSlider.instantaneousCallbacks = YES;
	self.paginationSlider.layoutStrategy = WAPaginationSliderLessDotsLayoutStrategy;
	[self.paginationSlider irBind:@"currentPage" toObject:self.paginatedView keyPath:@"currentPage" options:nil];
		
}

- (void) setContextControlsVisible:(BOOL)contextControlsVisible animated:(BOOL)animated {

	NSLog(@"TBD %s", __PRETTY_FUNCTION__);

}

- (IRDiscreteLayoutManager *) discreteLayoutManager {

	if (discreteLayoutManager)
		return discreteLayoutManager;
		
	self.discreteLayoutManager = [IRDiscreteLayoutManager new];
	self.discreteLayoutManager.delegate = self;
	self.discreteLayoutManager.dataSource = self;
	return self.discreteLayoutManager;

}

- (NSArray *) layoutGrids {

	if (layoutGrids)
		return layoutGrids;
		
	layoutGrids = [self newLayoutGrids];
	return layoutGrids;

}

- (void) viewDidUnload {

	[self.paginationSlider irUnbind:@"currentPage"];
	[self.paginatedView irRemoveObserverBlocksForKeyPath:@"currentPage"];

	self.discreteLayoutManager = nil;
	self.discreteLayoutResult = nil;	//	TBD: Not really?
	
	[super viewDidUnload];

}

-	(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  
	return YES;
	
}

- (void) refreshData {

	//	Explicitly do nothing as otherwise it interferes with global entity syncing

}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	
	if (self.paginatedView.numberOfPages)
		[self adjustPageView:[self.paginatedView existingPageAtIndex:self.paginatedView.currentPage] usingGridAtIndex:self.paginatedView.currentPage];
	
}

//	- (void) viewDidAppear:(BOOL)animated {
//
//		[super viewDidAppear:animated];
//		
//		[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(performReadingProgressSync) object:nil];
//		[self performSelector:@selector(performReadingProgressSync) withObject:nil afterDelay:1];
//		
//	}

- (void) controllerWillChangeContent:(NSFetchedResultsController *)controller {

	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		[super controllerWillChangeContent:controller];

}

- (void) controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	
	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		[super controller:controller didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
	
	switch (type) {
		
		case NSFetchedResultsChangeDelete:
		case NSFetchedResultsChangeInsert:
		case NSFetchedResultsChangeMove: {
			self.requiresRecalculationOnFetchedResultsChangeEnd = YES;
			break;
		}
		
		case NSFetchedResultsChangeUpdate: {
				
			if (!self.requiresRecalculationOnFetchedResultsChangeEnd)
			if ([anObject isKindOfClass:[WAArticle class]]) {
				
				WAArticleViewController *articleVC = [self cachedArticleViewControllerForArticle:anObject];
				[articleVC reloadData];
				
				self.requiresRecalculationOnFetchedResultsChangeEnd = YES;
				
			}
			
			break;
			
		}
				
	}
		
}

- (void) controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {

	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		[super controller:controller didChangeSection:sectionInfo atIndex:sectionIndex forChangeType:type];
	
	self.requiresRecalculationOnFetchedResultsChangeEnd = YES;

}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {

	if (self.requiresRecalculationOnFetchedResultsChangeEnd) {
	
		if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
			[super controllerDidChangeContent:controller];
			
	}

}

- (void) reloadViewContents {

	//	Should never be called when the paginated view is busy
	if (![self isViewLoaded])
		return;
	
	if (self.paginatedView.hidden) {
		[self performSelector:_cmd withObject:nil afterDelay:0.5];
		return;
	}

	NSError *layoutError = nil;
	IRDiscreteLayoutResult *result = [self.discreteLayoutManager calculatedResultWithReference:self.discreteLayoutResult strategy:IRCompareScoreLayoutStrategy error:&layoutError];
	
	if (!result) {
	
		//	Choked, probably gather data here?
		
		NSLog(@"Discrete layout manager choked on calculation with reference: %@", layoutError);
		result = [self.discreteLayoutManager calculatedResultWithReference:nil strategy:IRCompareScoreLayoutStrategy error:&layoutError];
		
		if (!result) {
			
			NSLog(@"Layout manager choked on calculation with no reference: %@", layoutError);
			result = [self.discreteLayoutManager calculatedResultWithReference:nil strategy:IRRandomLayoutStrategy error:&layoutError];
			
			if (!result) {
			
				NSLog(@"Layout manager choked at last resort: %@", layoutError);
			
			}
			
		}
		
	}
	
	self.discreteLayoutResult = result;
	
	NSUInteger lastCurrentPage = self.paginatedView.currentPage;
	
	[self.paginatedView reloadViews];
	self.paginationSlider.numberOfPages = self.paginatedView.numberOfPages;
	
	//	TBD: Cache contents of the previous screen, and then do some page index matching
	//	Instead of going back to the last current page, since we might have nothing left on the current page
	//	And things can get garbled very quickly
	
	if (self.presentedArticle) {
	
		[self.paginatedView scrollToPageAtIndex:[self gridIndexOfArticle:self.presentedArticle] animated:NO];
	
	} else {
	
		if ((self.paginatedView.numberOfPages - 1) >= lastCurrentPage)
			[self.paginatedView scrollToPageAtIndex:lastCurrentPage animated:NO];
		
	}

}

- (void) enqueueInterfaceUpdate:(void(^)(void))aBlock sender:(WAArticleViewController *)controller {

	if (!aBlock)
		return;

	NSParameterAssert([self isViewLoaded]);
	NSParameterAssert(self.discreteLayoutResult);
	
	CGSize const contentSize = self.paginatedView.frame.size;
	
	NSUInteger const fromPage = self.paginatedView.currentPage;
	IRDiscreteLayoutGrid * const fromUntransformedGrid = [self.discreteLayoutResult.grids objectAtIndex:fromPage];
	IRDiscreteLayoutGrid * const fromGrid = [fromUntransformedGrid transformedGridWithPrototype:[fromUntransformedGrid bestCounteprartPrototypeForAspectRatio:[self currentAspectRatio]]];
	
	fromGrid.contentSize = contentSize;
	
	aBlock();
	
	NSUInteger articlePage = [self gridIndexOfArticle:controller.article];
	[self.paginatedView scrollToPageAtIndex:articlePage animated:NO];
	
	NSUInteger const toPage = (articlePage != NSNotFound) ? articlePage : self.paginatedView.currentPage;
	IRDiscreteLayoutGrid * const toUntransformedGrid = [self.discreteLayoutResult.grids objectAtIndex:toPage];
	IRDiscreteLayoutGrid * const toGrid = [toUntransformedGrid transformedGridWithPrototype:[toUntransformedGrid bestCounteprartPrototypeForAspectRatio:[self currentAspectRatio]]];
	toGrid.contentSize = contentSize;
	
	NSParameterAssert(fromGrid && toGrid);
	
	IRDiscreteLayoutChangeSet *changeSet = [IRDiscreteLayoutChangeSet changeSetFromGrid:fromGrid toGrid:toGrid];
	
	UIView *containerView = self.paginatedView.superview;
	UIView *pageView = [self newPageContainerView];
	
	NSMutableArray *preconditionBlocks = [NSMutableArray array];
	NSMutableArray *animationBlocks = [NSMutableArray array];
	
	self.paginatedView.hidden = YES;
	pageView.frame = [containerView convertRect:[self.paginatedView pageRectForIndex:toPage] fromView:self.paginatedView.scrollView];
	
	[containerView addSubview:pageView];
	
	//	Every single item should have at least one backing view — either it swaps in, or out, or so
	
	[changeSet enumerateChangesWithBlock: ^ (WAArticle *item, IRDiscreteLayoutItemChangeType changeType) {
	
		NSCParameterAssert([item isKindOfClass:[WAArticle class]]);
	
		IRDiscreteLayoutArea *fromArea = [fromGrid areaForItem:item];
		IRDiscreteLayoutArea *toArea = [toGrid areaForItem:item];
		
		UIView *itemView = [self representingViewForItem:item];
		NSCParameterAssert(itemView);
		
		CGRect fromRect = fromArea.layoutBlock ? fromArea.layoutBlock(fromArea, item) : CGRectNull;
		CGRect toRect = toArea.layoutBlock ? toArea.layoutBlock(toArea, item) : CGRectNull;
		
		[preconditionBlocks irEnqueueBlock:^{

			[pageView addSubview:itemView];
			NSParameterAssert(itemView.superview == pageView);
			
		}];

		[animationBlocks irEnqueueBlock:^{
			
			NSParameterAssert(itemView.superview == pageView);
			
			NSParameterAssert(
				CGRectContainsRect(
					itemView.window.bounds,
					[itemView.window convertRect:itemView.frame fromView:itemView.superview]
				)
			);
			
		}];
		
		switch (changeType) {
		
			case IRDiscreteLayoutItemChangeInserting: {
				
				[preconditionBlocks irEnqueueBlock:^{

					NSParameterAssert(CGRectEqualToRect(fromRect, CGRectNull) && !CGRectEqualToRect(toRect, CGRectNull));
					itemView.frame = toRect;
					itemView.alpha = 0;
				
				}];
				
				[animationBlocks irEnqueueBlock:^{
					itemView.alpha = 1;
				}];
				
				break;
				
			}
			
			case IRDiscreteLayoutItemChangeDeleting: {
			
				[preconditionBlocks irEnqueueBlock:^{

					NSParameterAssert(!CGRectEqualToRect(fromRect, CGRectNull) && CGRectEqualToRect(toRect, CGRectNull));
					itemView.frame = fromRect;
					itemView.alpha = 1;
				
				}];
				
				[animationBlocks irEnqueueBlock:^{
					itemView.alpha = 0;
				}];
				
				break;
				
			}
			
			case IRDiscreteLayoutItemChangeRelayout: {
			
				[preconditionBlocks irEnqueueBlock:^{

					NSParameterAssert(!CGRectEqualToRect(fromRect, CGRectNull) && !CGRectEqualToRect(toRect, CGRectNull));
					itemView.frame = fromRect;
					
				}];
				
				[animationBlocks irEnqueueBlock:^{
					itemView.frame = toRect;
				}];
			
				break;
				
			}
			
			case IRDiscreteLayoutItemChangeNone: {
				
				[preconditionBlocks irEnqueueBlock:^{

					NSParameterAssert(!CGRectEqualToRect(fromRect, CGRectNull) && !CGRectEqualToRect(toRect, CGRectNull) && CGRectEqualToRect(fromRect, toRect));
					
					itemView.frame = fromRect;
				
				}];
				
				break;
				
			}
		
		};
		
	}];
	
	//	TBD: The views should relayout during animation, not before or after
	
	[self.view layoutIfNeeded];
	[preconditionBlocks irExecuteAllObjectsAsBlocks];
	
	UIViewAnimationOptions options = UIViewAnimationOptionOverrideInheritedDuration|UIViewAnimationOptionLayoutSubviews;
	
	[UIView animateWithDuration:0.5f delay:0 options:options animations:^{
		
		[animationBlocks irExecuteAllObjectsAsBlocks];
	
	} completion: ^ (BOOL finished) {
	
		[pageView removeFromSuperview];
		self.paginatedView.hidden = NO;
		
		[self reloadViewContents];
		
	}];
	
}

- (void) presentArticleViewController:(WAArticleViewController *)controller animated:(BOOL)animated completion:(void(^)(void))callback {

	NSUInteger index = [self gridIndexOfArticle:controller.article];
	
	[self.paginatedView scrollToPageAtIndex:index animated:animated];
	
	if (animated) {
	
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^ {
		
			if (callback)
				callback();
		
		});
	
	} else {
	
		if (callback)
			callback();
	
	}

}

- (NSUInteger) numberOfItemsForLayoutManager:(IRDiscreteLayoutManager *)manager {

  return [self.fetchedResultsController.fetchedObjects count];

}

- (id<IRDiscreteLayoutItem>) layoutManager:(IRDiscreteLayoutManager *)manager itemAtIndex:(NSUInteger)index {

  return (id<IRDiscreteLayoutItem>)[self.fetchedResultsController.fetchedObjects objectAtIndex:index];

}

- (NSInteger) layoutManager:(IRDiscreteLayoutManager *)manager indexOfLayoutItem:(id<IRDiscreteLayoutItem>)item {

	return [self.fetchedResultsController.fetchedObjects indexOfObject:item];

}

- (NSUInteger) numberOfLayoutGridsForLayoutManager:(IRDiscreteLayoutManager *)manager {

  return [self.layoutGrids count];

}

- (id<IRDiscreteLayoutItem>) layoutManager:(IRDiscreteLayoutManager *)manager layoutGridAtIndex:(NSUInteger)index {

  return (id<IRDiscreteLayoutItem>)[self.layoutGrids objectAtIndex:index];

}

- (NSInteger) layoutManager:(IRDiscreteLayoutManager *)manager indexOfLayoutGrid:(IRDiscreteLayoutGrid *)grid {

	return [self.layoutGrids indexOfObject:grid];

}

- (NSUInteger) numberOfViewsInPaginatedView:(IRPaginatedView *)paginatedView {

	return [self.discreteLayoutResult.grids count];

}

- (UIView *) viewForPaginatedView:(IRPaginatedView *)aPaginatedView atIndex:(NSUInteger)index {

	UIView *returnedView = [self newPageContainerView];
	returnedView.bounds = aPaginatedView.bounds;
	
	IRDiscreteLayoutGrid *viewGrid = (IRDiscreteLayoutGrid *)[self.discreteLayoutResult.grids objectAtIndex:index];
	
	NSMutableArray *pageElements = [NSMutableArray arrayWithCapacity:[viewGrid.layoutAreas count]];
	
	CGSize oldContentSize = viewGrid.contentSize;
	viewGrid.contentSize = aPaginatedView.frame.size;
	
	for (IRDiscreteLayoutArea *area in viewGrid.layoutAreas) {
		
		if (area.item) {
	
			UIView *placedSubview = (UIView *)(area.displayBlock(area, area.item));
			NSParameterAssert(placedSubview);
			placedSubview.frame = area.layoutBlock(area, area.item);
			placedSubview.autoresizingMask = UIViewAutoresizingNone;
			[pageElements addObject:placedSubview];
			[returnedView addSubview:placedSubview];
	
		}
		
	}
	
	viewGrid.contentSize = oldContentSize;
	
	objc_setAssociatedObject(returnedView, &kWADiscreteArticlePageElements, pageElements, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	[returnedView setNeedsLayout];
	
	[self adjustPageView:returnedView usingGridAtIndex:index];
	
	return returnedView;

}

- (void) paginatedView:(IRPaginatedView *)paginatedView didShowView:(UIView *)aView atIndex:(NSUInteger)index {

	if ([self.discreteLayoutResult.grids count] <= index)
		return;
	
	IRDiscreteLayoutGrid *viewGrid = (IRDiscreteLayoutGrid *)[self.discreteLayoutResult.grids objectAtIndex:index];
	
	for (IRDiscreteLayoutArea *area in viewGrid.layoutAreas) {
	
		WAArticle *article = (WAArticle *)area.item;
		if (article) {

			NSCParameterAssert([article isKindOfClass:[WAArticle class]]);
			
			[article.representingFile thumbnailImage];
					
			for (WAPreview *aPreview in article.previews)
				[aPreview.graphElement thumbnail];
		
		}
	
	}
	
}

- (UIViewController *) viewControllerForSubviewAtIndex:(NSUInteger)index inPaginatedView:(IRPaginatedView *)paginatedView {

	return nil;

}

- (void) adjustPageViewAtIndex:(NSUInteger)anIndex {

	if (anIndex == NSNotFound)
		return;
	
	UIView *currentPageView = [self.paginatedView existingPageAtIndex:anIndex];
	
	if (currentPageView)
		[self adjustPageView:currentPageView usingGridAtIndex:anIndex];

}

- (CGFloat) currentAspectRatio {

	UIWindow *usedWindow = self.view.window;
	if (!usedWindow)
		usedWindow = [UIApplication sharedApplication].keyWindow;
	
	NSParameterAssert(usedWindow);

	CGRect currentTransformedApplicationFrame = CGRectApplyAffineTransform(
		[usedWindow.screen applicationFrame],
		((CGAffineTransform[]){
			[UIInterfaceOrientationPortrait] = CGAffineTransformMakeRotation(0),
			[UIInterfaceOrientationPortraitUpsideDown] = CGAffineTransformMakeRotation(M_PI),
			[UIInterfaceOrientationLandscapeLeft] = CGAffineTransformMakeRotation(-0.5 * M_PI),
			[UIInterfaceOrientationLandscapeRight] = CGAffineTransformMakeRotation(0.5 * M_PI)
		})[self.interfaceOrientation]
	);
	
	CGFloat ratio = CGRectGetWidth(currentTransformedApplicationFrame) / CGRectGetHeight(currentTransformedApplicationFrame);
	NSCParameterAssert(isnormal(ratio));
	
	return ratio;

}

- (void) adjustPageView:(UIView *)currentPageView usingGridAtIndex:(NSUInteger)anIndex {

	//	Find the best grid alternative in allDestinations, and then enumerate its layout areas, using the provided layout blocks to relayout all the element representing views in the current paginated view page.
	
	if ([self.discreteLayoutResult.grids count] < (anIndex + 1))
		return;

	IRDiscreteLayoutGrid *currentPageGrid = [self.discreteLayoutResult.grids objectAtIndex:anIndex];
	
	[self adjustPageView:currentPageView withGrid:currentPageGrid];

}

- (void) adjustPageView:(UIView *)currentPageView withGrid:(IRDiscreteLayoutGrid *)currentPageGrid {

	NSArray *currentPageElements = objc_getAssociatedObject(currentPageView, &kWADiscreteArticlePageElements);
	
	IRDiscreteLayoutGrid *transformedGrid = [currentPageGrid transformedGridWithPrototype:[currentPageGrid bestCounteprartPrototypeForAspectRatio:[self currentAspectRatio]]];
	
	CGSize oldContentSize = transformedGrid.contentSize;
	transformedGrid.contentSize = self.paginatedView.frame.size;
	
	[transformedGrid.layoutAreas enumerateObjectsUsingBlock:^(IRDiscreteLayoutArea *area, NSUInteger idx, BOOL *stop) {
	
		if (!area.item)
			return;
		
		UIView *itemView = (UIView *)[currentPageElements objectAtIndex:idx];
		CGRect itemViewFrame = area.layoutBlock(area, area.item);
		
		if (itemView.alpha != 1)
			itemView.alpha = 1;
		
		if (![itemView isDescendantOfView:currentPageView])
			[currentPageView addSubview:itemView];
		
		if (!CGRectEqualToRect(itemView.frame, itemViewFrame))
			itemView.frame = itemViewFrame;
		
	}];
							
	transformedGrid.contentSize = oldContentSize;

}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	NSUInteger const currentPage = self.paginatedView.currentPage;
	
	if (currentPage > 0)
		[self adjustPageViewAtIndex:(currentPage - 1)];
	
	[self adjustPageViewAtIndex:currentPage];
	[self adjustPageViewAtIndex:(currentPage + 1)];
	
	[self.paginatedView irRemoveAnimationsRecusively:YES];
	
}

- (NSUInteger) gridIndexOfArticle:(WAArticle *)anArticle {

	NSArray *grids = self.discreteLayoutResult.grids;
	
	for (IRDiscreteLayoutGrid *grid in grids)
		if ([grid areaForItem:anArticle])
			return [grids indexOfObject:grid];
	
	return NSNotFound;

}

- (NSString *) captionForProposedCaption:(NSString *)proposedCaption forPageAtIndex:(NSUInteger)index inPaginationSlider:(WAPaginationSlider *)aSlider {

	if (self.discreteLayoutResult) {
		
		IRDiscreteLayoutGrid *targetGrid = [self.discreteLayoutResult.grids objectAtIndex:index];
		NSArray *sortedItems = [[targetGrid items] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:
		
			[NSSortDescriptor sortDescriptorWithKey:@"presentationDate" ascending:YES],
		
		nil]];
		
		if ([sortedItems count]) {
		
			NSDate *fromDate = ((WAArticle *)[sortedItems objectAtIndex:0]).presentationDate;
			NSDate *toDate = ((WAArticle *)[sortedItems lastObject]).presentationDate;
			
			if ([fromDate isEqualToDate:toDate])
				return [fromDate description];
			
			NSString *fromDateString = [NSDateFormatter localizedStringFromDate:fromDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
			NSString *toDateString = [NSDateFormatter localizedStringFromDate:toDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
			
			if ([fromDateString isEqualToString:toDateString])
				return fromDateString;
			
			return [NSString stringWithFormat:@"%@ – %@", fromDateString, toDateString];
		
		}
		
	}
	
	return proposedCaption;

}

- (void) paginationSlider:(WAPaginationSlider *)slider didMoveToPage:(NSUInteger)destinationPage {

	NSParameterAssert(destinationPage >= 0);
	NSParameterAssert(destinationPage < self.paginatedView.numberOfPages);

	if (self.paginatedView.currentPage == destinationPage)
		return;
	
	if (![slider.slider isTracking]) {
	
		UIViewAnimationOptions options = UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState;
		[UIView animateWithDuration:0.3 delay:0 options:options animations:^{
			[self.paginatedView scrollToPageAtIndex:destinationPage animated:NO];			
		} completion:nil];
		
	}
	
}

- (UIView *) viewForAnnotation:(WAPaginationSliderAnnotation *)anAnnotation inPaginationSlider:(WAPaginationSlider *)aSlider {

	return nil;

	//	NSParameterAssert(anAnnotation == self.lastReadingProgressAnnotation);
	//	
	//	return self.lastReadingProgressAnnotationView;

}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {

	return ![self.paginationSlider hitTest:[touch locationInView:self.paginationSlider] withEvent:nil];

}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {

	return YES;

}

- (NSArray *) debugActionSheetControllerActions {

	NSMutableArray *returnedActions = [[super debugActionSheetControllerActions] mutableCopy];
	
	if (!WAAdvancedFeaturesEnabled())
		return returnedActions;
		
	__weak WAOverviewController *nrSelf = self;

	[returnedActions addObject:[IRAction actionWithTitle:@"Reflow" block: ^ {
		
		[nrSelf reloadViewContents];
		
	}]];
	
	[returnedActions addObject:[IRAction actionWithTitle:@"Pounce" block: ^ {
	
		__block void (^pounce)(void) = [^ {
	
			IRPaginatedView *ownPaginatedView = nrSelf.paginatedView;
			
			if (ownPaginatedView.currentPage == 0) {
			
				[ownPaginatedView scrollToPageAtIndex:(ownPaginatedView.numberOfPages - 1) animated:YES];
			
			} else {

				[ownPaginatedView scrollToPageAtIndex:0 animated:YES];
			
			}
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), pounce);
		
		} copy];
		
		pounce();
		
	}]];
	
	return returnedActions;
	
}

- (void) dealloc {

	[self.paginationSlider irUnbind:@"currentPage"];
	[self.paginatedView irRemoveObserverBlocksForKeyPath:@"currentPage"];
		
	[[NSNotificationCenter defaultCenter] removeObserver:self];

}

@end
