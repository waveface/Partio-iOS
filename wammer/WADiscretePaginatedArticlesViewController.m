//
//  WADiscretePaginatedArticlesViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/31/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import "WADiscretePaginatedArticlesViewController.h"
#import "IRDiscreteLayoutManager.h"
#import "WADataStore.h"

#import "WAArticleViewController.h"
#import "WAPaginatedArticlesViewController.h"

#import "WAOverlayBezel.h"
#import "CALayer+IRAdditions.h"

#import "WAFauxRootNavigationController.h"
#import "WAEightPartLayoutGrid.h"

#import "WANavigationBar.h"

#import "WARemoteInterface.h"
#import "WAArticle.h"
#import "WAArticle+WARemoteInterfaceEntitySyncing.h"

#import "IRConcaveView.h"

#import "WAViewController.h"

#import "WAGestureWindow.h"


static NSString * const kWADiscreteArticlePageElements = @"kWADiscreteArticlePageElements";
static NSString * const kWADiscreteArticleViewControllerOnItem = @"kWADiscreteArticleViewControllerOnItem";
static NSString * const kWADiscreteArticlesViewLastUsedLayoutGrids = @"kWADiscreteArticlesViewLastUsedLayoutGrids";


@interface WADiscretePaginatedArticlesViewController () <IRDiscreteLayoutManagerDelegate, IRDiscreteLayoutManagerDataSource, WAArticleViewControllerPresenting, UIGestureRecognizerDelegate, WAPaginationSliderDelegate>

- (void) handleApplicationDidBecomeActive:(NSNotification *)aNotification;
- (void) handleApplicationDidEnterBackground:(NSNotification *)aNotification;

@property (nonatomic, readwrite, retain) IRDiscreteLayoutManager *discreteLayoutManager;
@property (nonatomic, readwrite, retain) IRDiscreteLayoutResult *discreteLayoutResult;
@property (nonatomic, readwrite, retain) NSArray *layoutGrids;
@property (nonatomic, readwrite, assign) BOOL requiresRecalculationOnFetchedResultsChangeEnd;

- (UIView *) representingViewForItem:(WAArticle *)anArticle;
- (void) adjustPageViewAtIndex:(NSUInteger)anIndex;
- (void) adjustPageViewAtIndex:(NSUInteger)anIndex withAdditionalAdjustments:(void(^)(UIView *aSubview))aBlock;
- (void) adjustPageView:(UIView *)aPageView usingGridAtIndex:(NSUInteger)anIndex;

@property (nonatomic, readonly, retain) WAPaginatedArticlesViewController *paginatedArticlesViewController;

- (void) updateLastReadingProgressAnnotation;

- (NSUInteger) gridIndexOfLastReadArticle;
- (NSUInteger) gridIndexOfArticle:(WAArticle *)anArticle;

- (void) performReadingProgressSync;	//	will transition and stuff
- (void) retrieveLatestReadingProgress;
- (void) retrieveLatestReadingProgressWithCompletion:(void(^)(NSTimeInterval timeTaken))aBlock;
- (void) updateLatestReadingProgressWithIdentifier:(NSString *)anIdentifier;
- (void) updateLatestReadingProgressWithIdentifier:(NSString *)anIdentifier completion:(void(^)(BOOL didUpdate))aBlock;

@property (nonatomic, readwrite, retain) NSString *lastReadObjectIdentifier;
@property (nonatomic, readwrite, retain) NSString *lastHandledReadObjectIdentifier;
@property (nonatomic, readwrite, retain) WAPaginationSliderAnnotation *lastReadingProgressAnnotation;
@property (nonatomic, readwrite, retain) UIView *lastReadingProgressAnnotationView;

- (void) presentDetailedContextForArticle:(NSURL *)anObjectURI;
- (void) presentDetailedContextForArticle:(NSURL *)anObjectURI animated:(BOOL)animated;
- (void) presentDetailedContextForArticle:(NSURL *)anObjectURI usingAnimation:(WAArticleContextAnimation)animation;

@end


@implementation WADiscretePaginatedArticlesViewController
@synthesize paginationSliderSlot;
@synthesize paginationSlider, discreteLayoutManager, discreteLayoutResult, layoutGrids, paginatedView;
@synthesize requiresRecalculationOnFetchedResultsChangeEnd;
@synthesize paginatedArticlesViewController;
@synthesize lastReadObjectIdentifier, lastHandledReadObjectIdentifier, lastReadingProgressAnnotation, lastReadingProgressAnnotationView;

- (WAPaginatedArticlesViewController *) paginatedArticlesViewController {

	if (paginatedArticlesViewController)
		return paginatedArticlesViewController;
		
	paginatedArticlesViewController = [[WAPaginatedArticlesViewController alloc] init];
  paginatedArticlesViewController.delegate = self.delegate;
  
	return paginatedArticlesViewController;

}

- (id) init {

	self = [self initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];
	if (!self)
		return nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	return self;

}

- (void) handleApplicationDidBecomeActive:(NSNotification *)aNotification {

	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(performReadingProgressSync) object:nil];
	[self performSelector:@selector(performReadingProgressSync) withObject:nil afterDelay:1];

}

- (void) handleApplicationDidEnterBackground:(NSNotification *)aNotification {

	if (![self isViewLoaded])
		return;
		
	NSArray *allGrids = self.discreteLayoutResult.grids;
	if (![allGrids count])
		return;

	IRDiscreteLayoutGrid *grid = [allGrids objectAtIndex:self.paginatedView.currentPage];
	
	NSString *lastArticleID = ((WAArticle *)[grid layoutItemForAreaNamed:[grid.layoutAreaNames lastObject]]).identifier;
	if (!lastArticleID)
		return;
	
	__block UIBackgroundTaskIdentifier taskID = UIBackgroundTaskInvalid;
	taskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
	[self updateLatestReadingProgressWithIdentifier:lastArticleID completion:^(BOOL didUpdate) {
		[[UIApplication sharedApplication] endBackgroundTask:taskID];
	}];
	
}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	__block __typeof__(self) nrSelf = self;
	
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPatternLinedWood"]];
	self.view.opaque = YES;
	((WAView *)self.view).onLayoutSubviews = ^ {
	
		if (!nrSelf.paginatedView.numberOfPages)
			return;
		NSUInteger currentPage = nrSelf.paginatedView.currentPage;
		UIView *pageView = [nrSelf.paginatedView existingPageAtIndex:currentPage];
		[nrSelf adjustPageView:pageView usingGridAtIndex:currentPage];
	
	};
	
	__block IRPaginatedView *nrPaginatedView = self.paginatedView;
	self.paginatedView.backgroundColor = nil;
	self.paginatedView.horizontalSpacing = 32.0f;
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
	
	self.paginationSliderSlot.backgroundColor = [UIColor colorWithWhite:0 alpha:0.125];
	self.paginationSliderSlot.innerShadow = [IRShadow shadowWithColor:[UIColor colorWithWhite:0 alpha:0.625] offset:(CGSize){ 0, 2 } spread:6];
	self.paginationSliderSlot.layer.cornerRadius = 4.0f;
	self.paginationSliderSlot.layer.masksToBounds = YES;

}

- (UIView *) representingViewForItem:(WAArticle *)anArticle {

	__block __typeof__(self) nrSelf = self;
	__block WAArticleViewController *articleViewController = nil;
	
	articleViewController = objc_getAssociatedObject(anArticle, &kWADiscreteArticleViewControllerOnItem);
	NSURL *objectURI = [[anArticle objectID] URIRepresentation];
	
	if (!articleViewController) {
		
		articleViewController = [WAArticleViewController controllerForArticle:objectURI usingPresentationStyle:[WAArticleViewController suggestedDiscreteStyleForArticle:anArticle]];
		objc_setAssociatedObject(anArticle, &kWADiscreteArticleViewControllerOnItem, articleViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		
	}
	
	articleViewController.onViewDidLoad = ^ (WAArticleViewController *loadedVC, UIView *loadedView) {
		
		((UIView *)loadedVC.view.imageStackView).userInteractionEnabled = NO;
		
	};
	
	articleViewController.onPresentingViewController = ^ (void(^action)(UIViewController <WAArticleViewControllerPresenting> *parentViewController)) {
		
		action(nrSelf);
		
	};
	
	articleViewController.onViewTap = ^ {
	
		[nrSelf updateLatestReadingProgressWithIdentifier:articleViewController.article.identifier];
		[nrSelf presentDetailedContextForArticle:[[articleViewController.article objectID] URIRepresentation] animated:YES];		
		
	};
	
	articleViewController.onViewPinch = ^ (UIGestureRecognizerState state, CGFloat scale, CGFloat velocity) {
	
		if (state == UIGestureRecognizerStateChanged)
		if (scale > 1.05f)
		if (velocity > 1.05f) {
		
			for (UIGestureRecognizer *gestureRecognizer in articleViewController.view.gestureRecognizers)
				gestureRecognizer.enabled = NO;
		
			articleViewController.onViewTap();
			
			for (UIGestureRecognizer *gestureRecognizer in articleViewController.view.gestureRecognizers)
				gestureRecognizer.enabled = YES;
			
		}
	
	};
	
	NSString *identifier = articleViewController.article.identifier;
	articleViewController.additionalDebugActions = [NSArray arrayWithObjects:
	
		[IRAction actionWithTitle:@"Make Last Read" block:^{
		
			nrSelf.lastReadObjectIdentifier = identifier;
			[nrSelf updateLastReadingProgressAnnotation];
		
		}],
		
	nil];

	return articleViewController.view;
	
}

- (void) setContextControlsVisible:(BOOL)contextControlsVisible animated:(BOOL)animated {

	NSLog(@"TBD %s", __PRETTY_FUNCTION__);

}

- (IRDiscreteLayoutGrid *) layoutManager:(IRDiscreteLayoutManager *)manager nextGridForContentsUsingGrid:(IRDiscreteLayoutGrid *)proposedGrid {
	
	NSMutableArray *lastResultantGrids = objc_getAssociatedObject(self, &kWADiscreteArticlesViewLastUsedLayoutGrids);
	
	if (![lastResultantGrids count]) {
		objc_setAssociatedObject(self, &kWADiscreteArticlesViewLastUsedLayoutGrids, nil, OBJC_ASSOCIATION_ASSIGN);
		return proposedGrid;
	}
	
	IRDiscreteLayoutGrid *prototype = [[[lastResultantGrids objectAtIndex:0] retain] autorelease];
	[lastResultantGrids removeObjectAtIndex:0];
	
	return prototype;

}

- (IRDiscreteLayoutManager *) discreteLayoutManager {

	if (discreteLayoutManager)
		return discreteLayoutManager;
		
	self.discreteLayoutManager = [[IRDiscreteLayoutManager new] autorelease];
	self.discreteLayoutManager.delegate = self;
	self.discreteLayoutManager.dataSource = self;
	return self.discreteLayoutManager;

}

- (NSArray *) layoutGrids {

	if (layoutGrids)
		return layoutGrids;

	__block __typeof__(self) nrSelf = self;
		
	IRDiscreteLayoutGridAreaDisplayBlock genericDisplayBlock = [[^ (IRDiscreteLayoutGrid *self, id anItem) {
	
		if (![anItem isKindOfClass:[WAArticle class]])
			return nil;
	
		return [nrSelf representingViewForItem:(WAArticle *)anItem];
	
	} copy] autorelease];
	
	NSMutableArray *enqueuedLayoutGrids = [NSMutableArray array];
	
	WAEightPartLayoutGrid *eightPartGrid = [WAEightPartLayoutGrid prototype];
	[enqueuedLayoutGrids addObject:eightPartGrid];
	eightPartGrid.validatorBlock = nil;
	eightPartGrid.displayBlock = genericDisplayBlock;
	
	layoutGrids = [enqueuedLayoutGrids retain];
	return layoutGrids;

}

- (void) viewDidUnload {

	[self.paginationSlider irUnbind:@"currentPage"];
	[self.paginatedView irRemoveObserverBlocksForKeyPath:@"currentPage"];

	self.discreteLayoutManager = nil;
	self.discreteLayoutResult = nil;
	[self setPaginationSliderSlot:nil];
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

- (void) viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];
	
	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(performReadingProgressSync) object:nil];
	[self performSelector:@selector(performReadingProgressSync) withObject:nil afterDelay:1];
	
}

- (void) performReadingProgressSync {

	static NSString * const kWADiscretePaginatedArticlesViewController_PerformingReadingProgressSync = @"WADiscretePaginatedArticlesViewController_PerformingReadingProgressSync";

	if (objc_getAssociatedObject(self, &kWADiscretePaginatedArticlesViewController_PerformingReadingProgressSync))
		return;
	
	objc_setAssociatedObject(self, &kWADiscretePaginatedArticlesViewController_PerformingReadingProgressSync, (id)kCFBooleanTrue, OBJC_ASSOCIATION_ASSIGN);

	NSUInteger lastPage = NSNotFound;
	if ([self isViewLoaded])
		lastPage = self.paginatedView.currentPage;
	
	NSString *capturedLastReadObjectID = self.lastReadObjectIdentifier;
	
	[[WARemoteInterface sharedInterface] beginPerformingAutomaticRemoteUpdates];
	
	[self retrieveLatestReadingProgressWithCompletion:^(NSTimeInterval timeTaken) {
	
		[[WARemoteInterface sharedInterface] endPerformingAutomaticRemoteUpdates];
	
		objc_setAssociatedObject(self, &kWADiscretePaginatedArticlesViewController_PerformingReadingProgressSync, nil, OBJC_ASSOCIATION_ASSIGN);
		
		if (![self isViewLoaded])
			return;
			
		//	FIXME if (!self.hasReceivedUserInteraction)
		
		if (timeTaken > 3)
			return;
		
		NSInteger currentIndex = [self gridIndexOfLastReadArticle];
		if (currentIndex == NSNotFound)
			return;
		
		if (self.paginatedView.currentPage != lastPage)
			return;
		
		if (![self.lastHandledReadObjectIdentifier isEqualToString:capturedLastReadObjectID]) {
			[self.paginatedView scrollToPageAtIndex:currentIndex animated:YES];
			self.lastHandledReadObjectIdentifier = self.lastReadObjectIdentifier;
		}
			
	}];	

}

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
		
		case NSFetchedResultsChangeUpdate:
		default: {
			//	No op
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

	if (self.requiresRecalculationOnFetchedResultsChangeEnd)
	if ([self irHasDifferentSuperInstanceMethodForSelector:_cmd])
		[super controllerDidChangeContent:controller];

}

- (void) reloadViewContents {

	if (self.discreteLayoutResult) {
		objc_setAssociatedObject(self, &kWADiscreteArticlesViewLastUsedLayoutGrids, [self.discreteLayoutResult.grids irMap: ^ (IRDiscreteLayoutGrid *aGridInstance, NSUInteger index, BOOL *stop) {
			return [aGridInstance isFullyPopulated] ? aGridInstance.prototype : nil;
		}], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	self.discreteLayoutResult = [self.discreteLayoutManager calculatedResult];
	objc_setAssociatedObject(self, &kWADiscreteArticlesViewLastUsedLayoutGrids, nil, OBJC_ASSOCIATION_ASSIGN);
	
	NSUInteger lastCurrentPage = self.paginatedView.currentPage;
	
	[self.paginatedView reloadViews];
	self.paginationSlider.numberOfPages = self.paginatedView.numberOfPages;
	
	//	TBD: Cache contents of the previous screen, and then do some page index matching
	//	Instead of going back to the last current page, since we might have nothing left on the current page
	//	And things can get garbled very quickly
	
	if ((self.paginatedView.numberOfPages - 1) >= lastCurrentPage)
		[self.paginatedView scrollToPageAtIndex:lastCurrentPage animated:NO];

}

- (NSUInteger) numberOfItemsForLayoutManager:(IRDiscreteLayoutManager *)manager {

  return [self.fetchedResultsController.fetchedObjects count];

}

- (id<IRDiscreteLayoutItem>) layoutManager:(IRDiscreteLayoutManager *)manager itemAtIndex:(NSUInteger)index {

  return (id<IRDiscreteLayoutItem>)[self.fetchedResultsController.fetchedObjects objectAtIndex:index];

}

- (NSUInteger) numberOfLayoutGridsForLayoutManager:(IRDiscreteLayoutManager *)manager {

  return [self.layoutGrids count];

}

- (id<IRDiscreteLayoutItem>) layoutManager:(IRDiscreteLayoutManager *)manager layoutGridAtIndex:(NSUInteger)index {

  return (id<IRDiscreteLayoutItem>)[self.layoutGrids objectAtIndex:index];

}

- (NSUInteger) numberOfViewsInPaginatedView:(IRPaginatedView *)paginatedView {

	return [self.discreteLayoutResult.grids count];

}

- (UIView *) viewForPaginatedView:(IRPaginatedView *)aPaginatedView atIndex:(NSUInteger)index {

	UIView *returnedView = [[[UIView alloc] initWithFrame:aPaginatedView.bounds] autorelease];
	returnedView.autoresizingMask = UIViewAutoresizingNone;
	returnedView.clipsToBounds = NO;
	returnedView.layer.shouldRasterize = YES;
	
	UIView *backdropView = [[[UIView alloc] initWithFrame:CGRectInset(returnedView.bounds, -16, -16)] autorelease];
	backdropView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	backdropView.backgroundColor = [UIColor whiteColor];
	backdropView.layer.shadowOpacity = 0.35;
	backdropView.layer.shadowOffset = (CGSize){ 0, 2 };
	[returnedView addSubview:backdropView];
	
	IRDiscreteLayoutGrid *viewGrid = (IRDiscreteLayoutGrid *)[self.discreteLayoutResult.grids objectAtIndex:index];
	
	NSMutableArray *pageElements = [NSMutableArray arrayWithCapacity:[viewGrid.layoutAreaNames count]];
	
	CGSize oldContentSize = viewGrid.contentSize;
	viewGrid.contentSize = aPaginatedView.frame.size;
	
	[viewGrid enumerateLayoutAreasWithBlock: ^ (NSString *name, id item, BOOL(^validatorBlock)(IRDiscreteLayoutGrid *self, id anItem), CGRect(^layoutBlock)(IRDiscreteLayoutGrid *self, id anItem), id(^displayBlock)(IRDiscreteLayoutGrid *self, id anItem)) {
	
		if (!item)
			return;
	
		UIView *placedSubview = (UIView *)displayBlock(viewGrid, item);
		NSParameterAssert(placedSubview);
		placedSubview.frame = layoutBlock(viewGrid, item);
		placedSubview.autoresizingMask = UIViewAutoresizingNone;
		[pageElements addObject:placedSubview];
		[returnedView addSubview:placedSubview];
				
	}];

	viewGrid.contentSize = oldContentSize;
	
	objc_setAssociatedObject(returnedView, &kWADiscreteArticlePageElements, pageElements, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	[returnedView setNeedsLayout];
	
	[self adjustPageView:returnedView usingGridAtIndex:index];
			
	return returnedView;

}

- (void) paginatedView:(IRPaginatedView *)paginatedView didShowView:(UIView *)aView atIndex:(NSUInteger)index {

	IRDiscreteLayoutGrid *viewGrid = (IRDiscreteLayoutGrid *)[self.discreteLayoutResult.grids objectAtIndex:index];
	[viewGrid enumerateLayoutAreasWithBlock: ^ (NSString *name, id item, BOOL(^validatorBlock)(IRDiscreteLayoutGrid *self, id anItem), CGRect(^layoutBlock)(IRDiscreteLayoutGrid *self, id anItem), id(^displayBlock)(IRDiscreteLayoutGrid *self, id anItem)) {
	
		WAArticle *representedArticle = (WAArticle *)item;
				
		if ([representedArticle.fileOrder count]) {
			WAFile *firstFile = (WAFile *)[representedArticle.managedObjectContext irManagedObjectForURI:[representedArticle.fileOrder objectAtIndex:0]];
			
			if (firstFile.thumbnailURL)
			if (![firstFile primitiveValueForKey:@"thumbnailFilePath"])
				[[IRRemoteResourcesManager sharedManager] retrieveResourceAtURL:[NSURL URLWithString:firstFile.thumbnailURL] usingPriority:NSOperationQueuePriorityHigh forced:NO withCompletionBlock:nil];
        
      if ([[WARemoteInterface sharedInterface] areExpensiveOperationsAllowed]) {
			
        //  No non-on-demand resource downloading by default
        //  TBD: Maybe just move it into syncing
        
        if (firstFile.resourceURL)
        if (![firstFile primitiveValueForKey:@"resourceFilePath"])
          [[IRRemoteResourcesManager sharedManager] retrieveResourceAtURL:[NSURL URLWithString:firstFile.resourceURL] usingPriority:NSOperationQueuePriorityLow forced:NO withCompletionBlock:nil];
      
      }
			
		}
			
		for (WAPreview *aPreview in representedArticle.previews)
			if (aPreview.graphElement.thumbnailURL)
			if (![aPreview.graphElement primitiveValueForKey:@"thumbnailFilePath"])
				[[IRRemoteResourcesManager sharedManager] retrieveResourceAtURL:[NSURL URLWithString:aPreview.graphElement.thumbnailURL] usingPriority:NSOperationQueuePriorityHigh forced:NO withCompletionBlock:nil];
	
	}];

}

- (UIViewController *) viewControllerForSubviewAtIndex:(NSUInteger)index inPaginatedView:(IRPaginatedView *)paginatedView {

	return nil;

}

- (void) adjustPageViewAtIndex:(NSUInteger)anIndex {

	[self adjustPageViewAtIndex:anIndex withAdditionalAdjustments:nil];

}

- (void) adjustPageView:(UIView *)currentPageView usingGridAtIndex:(NSUInteger)anIndex {

	//	Find the best grid alternative in allDestinations, and then enumerate its layout areas, using the provided layout blocks to relayout all the element representing views in the current paginated view page.
	
	if ([self.discreteLayoutResult.grids count] < (anIndex + 1))
		return;
	
	NSArray *currentPageElements = objc_getAssociatedObject(currentPageView, &kWADiscreteArticlePageElements);
	IRDiscreteLayoutGrid *currentPageGrid = [self.discreteLayoutResult.grids objectAtIndex:anIndex];
	NSSet *allDestinations = [currentPageGrid allTransformablePrototypeDestinations];
	NSSet *allIntrospectedGrids = [allDestinations setByAddingObject:currentPageGrid];
	IRDiscreteLayoutGrid *bestGrid = nil;
	
	CGFloat currentAspectRatio = ((^ {
	
		//	FIXME: Save this somewhere to avoid recalculating stuff again and again?

		CGAffineTransform orientationsToTransforms[] = {
			[UIInterfaceOrientationPortrait] = CGAffineTransformMakeRotation(0),
			[UIInterfaceOrientationPortraitUpsideDown] = CGAffineTransformMakeRotation(M_PI),
			[UIInterfaceOrientationLandscapeLeft] = CGAffineTransformMakeRotation(-0.5 * M_PI),
			[UIInterfaceOrientationLandscapeRight] = CGAffineTransformMakeRotation(0.5 * M_PI)
		};
		
		CGRect currentTransformedApplicationFrame = CGRectApplyAffineTransform(
			[[UIApplication sharedApplication].keyWindow.screen applicationFrame],
			orientationsToTransforms[[UIApplication sharedApplication].statusBarOrientation]
		);
		
		return CGRectGetWidth(currentTransformedApplicationFrame) / CGRectGetHeight(currentTransformedApplicationFrame);

	})());
	
	for (IRDiscreteLayoutGrid *aGrid in allIntrospectedGrids) {
		
		CGFloat bestGridAspectRatio = bestGrid.contentSize.width / bestGrid.contentSize.height;
		CGFloat currentGridAspectRatio = aGrid.contentSize.width / aGrid.contentSize.height;
		
		if (!bestGrid) {
			bestGrid = [[aGrid retain] autorelease];
			continue;
		}
		
		if (fabs(currentAspectRatio - bestGridAspectRatio) < fabs(currentAspectRatio - currentGridAspectRatio)) {
			continue;
		}
		
		bestGrid = [[aGrid retain] autorelease];
		
	}
	
	
	IRDiscreteLayoutGrid *transformedGrid = bestGrid;//[allDestinations anyObject];
	transformedGrid = [currentPageGrid transformedGridWithPrototype:(transformedGrid.prototype ? transformedGrid.prototype : transformedGrid)];
	
	CGSize oldContentSize = transformedGrid.contentSize;
	transformedGrid.contentSize = self.paginatedView.frame.size;
	[[currentPageGrid retain] autorelease];
			
	[transformedGrid enumerateLayoutAreasWithBlock: ^ (NSString *name, id item, BOOL(^validatorBlock)(IRDiscreteLayoutGrid *self, id anItem), CGRect(^layoutBlock)(IRDiscreteLayoutGrid *self, id anItem), id(^displayBlock)(IRDiscreteLayoutGrid *self, id anItem)) {
	
		if (!item)
			return;
	
		((UIView *)[currentPageElements objectAtIndex:[currentPageGrid.layoutAreaNames indexOfObject:name]]).frame = CGRectInset(layoutBlock(transformedGrid, item), 8, 8);
		
	}];
	
	transformedGrid.contentSize = oldContentSize;

}

- (void) adjustPageViewAtIndex:(NSUInteger)anIndex withAdditionalAdjustments:(void(^)(UIView *aSubview))aBlock {

	UIView *currentPageView = [self.paginatedView existingPageAtIndex:anIndex];	
	[self adjustPageView:currentPageView usingGridAtIndex:anIndex];
		
	if (aBlock)
		aBlock(currentPageView);

}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	void (^removeAnimations)(UIView *) = ^ (UIView *introspectedView) {
	
		__block void (^removeAnimationsOnView)(UIView *aView) = nil;
		
		removeAnimationsOnView = ^ (UIView *aView) {
		
			[aView.layer removeAllAnimations];

			for (UIView *aSubview in aView.subviews)
				removeAnimationsOnView(aSubview);
		
		};
		
		removeAnimationsOnView(introspectedView);

	};
	
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	
	removeAnimations(self.paginatedView);

	//	If the paginated view is currently showing a view constructed with information provided by a layout grid, and that layout grid’s prototype has a fully transformable target, grab that transformable prototype and do a transform, then reposition individual items
	
	if (self.paginatedView.currentPage > 0)
		[self adjustPageViewAtIndex:(self.paginatedView.currentPage - 1) withAdditionalAdjustments:removeAnimations];
	
	[self adjustPageViewAtIndex:self.paginatedView.currentPage withAdditionalAdjustments:removeAnimations];
	
	if ((self.paginatedView.currentPage + 1) < self.paginatedView.numberOfPages) {
		[self adjustPageViewAtIndex:(self.paginatedView.currentPage + 1) withAdditionalAdjustments:removeAnimations];
	}
	
	[CATransaction commit];
	
}

- (void) updateLastReadingProgressAnnotation {

	WAPaginationSliderAnnotation *annotation = self.lastReadingProgressAnnotation;
	if (annotation) {
		[self.paginationSlider addAnnotationsObject:annotation];
	} else {
		[self.paginationSlider removeAnnotations:[NSSet setWithArray:self.paginationSlider.annotations]];
	}
	
	[self.paginationSlider setNeedsAnnotationsLayout];
	[self.paginationSlider layoutSubviews];
	[self.paginationSlider setNeedsLayout];

}

- (NSUInteger) gridIndexOfLastReadArticle {

	__block WAArticle *lastReadArticle = nil;
	
	[[WADataStore defaultStore] fetchArticleWithIdentifier:self.lastReadObjectIdentifier usingContext:self.fetchedResultsController.managedObjectContext onSuccess: ^ (NSString *identifier, WAArticle *article) {
	
		lastReadArticle = article;
		
	}];
	
	if (!lastReadArticle)
		return NSNotFound;
	
	return [self gridIndexOfArticle:lastReadArticle];

}

- (NSUInteger) gridIndexOfArticle:(WAArticle *)anArticle {

	__block NSUInteger containingGridIndex = NSNotFound;

	IRDiscreteLayoutResult *lastLayoutResult = self.discreteLayoutResult;
	[lastLayoutResult.grids enumerateObjectsUsingBlock:^(IRDiscreteLayoutGrid *aGridInstance, NSUInteger gridIndex, BOOL *stop) {
	
		__block BOOL canStop = NO;
		
		[aGridInstance enumerateLayoutAreasWithBlock:^(NSString *name, id item, IRDiscreteLayoutGridAreaValidatorBlock validatorBlock, IRDiscreteLayoutGridAreaLayoutBlock layoutBlock, IRDiscreteLayoutGridAreaDisplayBlock displayBlock) {
			
			if ([item isEqual:anArticle]) {
				containingGridIndex = gridIndex;
				*stop = YES;
				canStop = YES;
			}
			
		}];
		
		*stop = canStop;
		
	}];
	
	return containingGridIndex;

}

- (WAPaginationSliderAnnotation *) lastReadingProgressAnnotation {

	NSUInteger gridIndex = [self gridIndexOfLastReadArticle];
	
	if (gridIndex == NSNotFound)
		return nil;
	
	if (!lastReadingProgressAnnotation) {
		lastReadingProgressAnnotation = [[WAPaginationSliderAnnotation alloc] init];
	}
	lastReadingProgressAnnotation.pageIndex = gridIndex;
	//	lastReadingProgressAnnotation.centerOffset = (CGPoint){, 0 };
	return lastReadingProgressAnnotation;

}

- (UIView *) lastReadingProgressAnnotationView {

	if (lastReadingProgressAnnotationView)
		return lastReadingProgressAnnotationView;
	
	lastReadingProgressAnnotationView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"WALastReadIndicator"]];
	[lastReadingProgressAnnotationView sizeToFit];
	
	return lastReadingProgressAnnotationView;

}

- (UIView *) viewForAnnotation:(WAPaginationSliderAnnotation *)anAnnotation inPaginationSlider:(WAPaginationSlider *)aSlider {

	if (anAnnotation == lastReadingProgressAnnotation)
		return self.lastReadingProgressAnnotationView;
	
	return nil;

}

- (void) paginationSlider:(WAPaginationSlider *)slider didMoveToPage:(NSUInteger)destinationPage {

	NSParameterAssert(destinationPage >= 0);
	NSParameterAssert(destinationPage < self.paginatedView.numberOfPages);

	if (self.paginatedView.currentPage == destinationPage)
		return;
	
	if ([slider.slider isTracking]) {
		UIViewAnimationOptions options = UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState;
		[UIView animateWithDuration:0.3 delay:0 options:options animations:^{
			[self.paginatedView scrollToPageAtIndex:destinationPage animated:NO];			
		} completion:nil];
		return;
	}
	
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
		[(id<UIScrollViewDelegate>)self.paginatedView scrollViewDidScroll:self.paginatedView.scrollView];
		[self.paginatedView.layer addAnimation:transition forKey:@"transition"];
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, transition.duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^ {
			[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		});
		
		[CATransaction commit];
	
	});
	
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {

	return ![self.paginationSlider hitTest:[touch locationInView:self.paginationSlider] withEvent:nil];

}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {

	return YES;

}

- (NSArray *) debugActionSheetControllerActions {
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (![defaults boolForKey:kWAAdvancedFeaturesEnabled])
		return nil;
	
	__block __typeof__(self) nrSelf = self; 
	
	return [[super debugActionSheetControllerActions] 
					arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:
																				 
																				 [IRAction actionWithTitle:@"Reflow" block: ^ {
						[nrSelf reloadViewContents];
						
					}],
																				 
																				 [IRAction actionWithTitle:@"Label Smoke" block: ^ {
						
						UIViewController *testingVC = [[(UIViewController *)[NSClassFromString(@"IRLabelTestingViewController") alloc] init] autorelease];
						__block UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:testingVC] autorelease];
						testingVC.navigationItem.rightBarButtonItem = [IRBarButtonItem itemWithTitle:@"Close" action:^{
							[navC dismissModalViewControllerAnimated:YES];
						}];
						navC.modalPresentationStyle = UIModalPresentationFormSheet;
						[[UIApplication sharedApplication].keyWindow.rootViewController presentModalViewController:navC animated:YES];
						
					}],
					nil]];
	
}

- (void) setLastReadObjectIdentifier:(NSString *)newLastReadObjectIdentifier {

	if (lastReadObjectIdentifier == newLastReadObjectIdentifier)
		return;
	
	[lastReadObjectIdentifier release];
	lastReadObjectIdentifier = [newLastReadObjectIdentifier retain];
	
	[self updateLastReadingProgressAnnotation];	//	?

}

- (void) updateLatestReadingProgressWithIdentifier:(NSString *)anIdentifier {

	[self updateLatestReadingProgressWithIdentifier:anIdentifier completion:nil];

}

- (void) updateLatestReadingProgressWithIdentifier:(NSString *)anIdentifier completion:(void(^)(BOOL didUpdate))aBlock {

	__block __typeof__(self) nrSelf = self;
	__block WAOverlayBezel *nrBezel = nil;
	
	BOOL usesBezel = [[NSUserDefaults standardUserDefaults] boolForKey:kWADebugLastScanSyncBezelsVisible];
	if (usesBezel) {
		nrBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
		nrBezel.caption = @"Set Last Scan";
		[nrBezel showWithAnimation:WAOverlayBezelAnimationFade];
	}
	
	[nrSelf retain];
	
	WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	[ri updateLastScannedPostInGroup:ri.primaryGroupIdentifier withPost:anIdentifier onSuccess:^{
		
		dispatch_async(dispatch_get_main_queue(), ^{
		
			nrSelf.lastReadObjectIdentifier = anIdentifier;	//	Heh
			[nrSelf autorelease];
			
			if (aBlock)
				aBlock(YES);
			
			if (usesBezel) {
				[nrBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
				nrBezel = [WAOverlayBezel bezelWithStyle:WACheckmarkBezelStyle];
				[nrBezel showWithAnimation:WAOverlayBezelAnimationNone];
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
					[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
				});
			}
			
		});
		
	} onFailure:^(NSError *error) {
	
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[nrSelf autorelease];
			
			if (aBlock)
				aBlock(NO);
			
			if (usesBezel) {
				[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
				nrBezel = [WAOverlayBezel bezelWithStyle:WAErrorBezelStyle];
				nrBezel.caption = @"Can’t Set";
				[nrBezel showWithAnimation:WAOverlayBezelAnimationNone];
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
					[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
				});
			}
		
		});
		
	}];

}
 
- (void) retrieveLatestReadingProgress {

	[self retrieveLatestReadingProgressWithCompletion:nil];

}

- (void) retrieveLatestReadingProgressWithCompletion:(void (^)(NSTimeInterval))aBlock {

	CFAbsoluteTime operationStart = CFAbsoluteTimeGetCurrent();
	
	[[WARemoteInterface sharedInterface] beginPostponingDataRetrievalTimerFiring];
				
	void (^cleanup)() = ^ {
	
		NSParameterAssert([NSThread isMainThread]);
		
		if (aBlock)
			aBlock((NSTimeInterval)(CFAbsoluteTimeGetCurrent() - operationStart));
	
		[[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
		
	};
	
	BOOL usesBezel = [[NSUserDefaults standardUserDefaults] boolForKey:kWADebugLastScanSyncBezelsVisible];
	
	__block __typeof__(self) nrSelf = self;
	
	
	__block WAOverlayBezel *nrBezel = nil;
	
	if (usesBezel) {
		nrBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
		nrBezel.caption = @"Get Last Scan";
		[nrBezel showWithAnimation:WAOverlayBezelAnimationFade];
	}
	
	WARemoteInterface *ri = [WARemoteInterface sharedInterface];
	WADataStore *ds = [WADataStore defaultStore];
	
	
	//	Retrieve the last scanned post in the primary group
	//	Before anything happens at all
	
	[ri retrieveLastScannedPostInGroup:ri.primaryGroupIdentifier onSuccess: ^ (NSString *lastScannedPostIdentifier) {
	
		dispatch_async(dispatch_get_main_queue(), ^{
		
			//	On retrieval completion, set it on the main queue
			//	Then ensure the object exists locally
			
			[ds fetchArticleWithIdentifier:lastScannedPostIdentifier usingContext:self.fetchedResultsController.managedObjectContext onSuccess:^(NSString *identifier, WAArticle *article) {
			
				//	If the object exists locally, go on, things are merry

				if (article) {
					
					nrSelf.lastReadObjectIdentifier = lastScannedPostIdentifier;
					
					if (usesBezel) {
						[nrBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
						nrBezel = [WAOverlayBezel bezelWithStyle:WACheckmarkBezelStyle];
						[nrBezel showWithAnimation:WAOverlayBezelAnimationNone];
						dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
							[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
						});
					}
					
					cleanup();
					return;
					
				}
				
				[nrBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
				nrBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
				nrBezel.caption = @"Loading";
				[nrBezel showWithAnimation:WAOverlayBezelAnimationNone];
				
				//	Otherwise, fetch stuff until things are tidy again
				
				[WAArticle synchronizeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:
					
					kWAArticleSyncFullyFetchOnlyStrategy, kWAArticleSyncStrategy,
					
					[[^ (BOOL hasDoneWorking, NSManagedObjectContext *temporalContext, NSArray *usedObjects, NSError *anError) {
					
						NSParameterAssert(!hasDoneWorking);
						
						NSError *savingError = nil;
						if (![temporalContext save:&savingError]) {
							NSLog(@"Error saving: %@", savingError);
							NSParameterAssert(NO);
						}
						
						//	Save would trigger UI update
					
					} copy] autorelease], kWAArticleSyncProgressCallback,
					
				nil] completion:^(BOOL didFinish, NSManagedObjectContext *temporalContext, NSArray *prospectiveUnsavedObjects, NSError *anError) {
				
					if (!didFinish) {
						
						dispatch_async(dispatch_get_main_queue(), ^ {

							[nrBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
							
							if (usesBezel) {
								nrBezel = [WAOverlayBezel bezelWithStyle:WAErrorBezelStyle];
								nrBezel.caption = @"Load Failed";
								[nrBezel showWithAnimation:WAOverlayBezelAnimationNone];
								dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
									[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
								});
							}

							cleanup();
							
						});
						
						return;
						
					}
				
					NSError *savingError = nil;
					if (![temporalContext save:&savingError]) {
						NSLog(@"Error saving: %@", savingError);
						NSParameterAssert(NO);
					}
						
					dispatch_async(dispatch_get_main_queue(), ^{

						[nrBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
						
						if (usesBezel) {
							nrBezel = [WAOverlayBezel bezelWithStyle:WACheckmarkBezelStyle];
							[nrBezel showWithAnimation:WAOverlayBezelAnimationNone];
							dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
								[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
							});
						}

						nrSelf.lastReadObjectIdentifier = lastScannedPostIdentifier;
						
						cleanup();
						
					});
					
					return;
					
				}];
				
			}];
		
		});
	
	} onFailure: ^ (NSError *error) {
	
		dispatch_async(dispatch_get_main_queue(), ^{

			[nrBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
			
			if (usesBezel) {
				nrBezel = [WAOverlayBezel bezelWithStyle:WAErrorBezelStyle];
				nrBezel.caption = @"Fetch Failed";
				[nrBezel showWithAnimation:WAOverlayBezelAnimationNone];
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
					[nrBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
				});
			}

			//	?
			
			cleanup();
		
		});
		
	}];

}

- (void) presentDetailedContextForArticle:(NSURL *)anObjectURI {

	[self presentDetailedContextForArticle:anObjectURI animated:YES];

}

- (void) presentDetailedContextForArticle:(NSURL *)anObjectURI animated:(BOOL)animated {

	BOOL usesFlip = [[NSUserDefaults standardUserDefaults] boolForKey:kWADebugUsesDiscreteArticleFlip];
	
	WAArticleContextAnimation animation = WAArticleContextAnimationDefault;
	
	if (!animated) {
		animation = WAArticleContextAnimationNone;
	} else if (usesFlip) {
		animation = WAArticleContextAnimationFlipAndScale;
	} else {
		animation = WAArticleContextAnimationCoverVertically;
	}

	[self presentDetailedContextForArticle:anObjectURI usingAnimation:animation];

}

- (void) presentDetailedContextForArticle:(NSURL *)articleURI usingAnimation:(WAArticleContextAnimation)animation {

	static BOOL const usesPaginatedContext = NO;
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	dispatch_async(dispatch_get_main_queue(), ^ {

		__block WAArticle *article = (WAArticle *)[self.managedObjectContext irManagedObjectForURI:articleURI];
		__block WADiscretePaginatedArticlesViewController *nrSelf = self;
		__block WAArticleViewController *articleViewController = objc_getAssociatedObject(article, &kWADiscreteArticleViewControllerOnItem);
		
		NSString * const kDismissBlock = [NSString stringWithFormat:@"%@_%s_Dismiss", NSStringFromClass([self class]), __PRETTY_FUNCTION__];
		
		__block UIViewController<WAArticleViewControllerPresenting> *shownArticleVC = ((^ {
		
			__block UIViewController<WAArticleViewControllerPresenting> *returnedVC = nil;
		
			if (usesPaginatedContext) {
				
				returnedVC = nrSelf.paginatedArticlesViewController;
				
				((WAPaginatedArticlesViewController *)returnedVC).context = [NSDictionary dictionaryWithObjectsAndKeys:
					articleURI, @"lastVisitedObjectURI",
				nil];
				
			} else {
			
				returnedVC = [WAArticleViewController controllerForArticle:articleURI usingPresentationStyle:WAFullFrameArticleStyleFromDiscreteStyle(articleViewController.presentationStyle)];
				
				((WAArticleViewController *)returnedVC).onPresentingViewController = ^ (void(^action)(UIViewController <WAArticleViewControllerPresenting> *parentViewController)) {
					if ([returnedVC.navigationController conformsToProtocol:@protocol(WAArticleViewControllerPresenting)]) {
						action((UIViewController <WAArticleViewControllerPresenting> *)returnedVC.navigationController);
					} else {
						action(nrSelf);
					}
				};
				
			}
			
			returnedVC.navigationItem.hidesBackButton = NO;
			returnedVC.navigationItem.leftBarButtonItem = WABackBarButtonItem(@"Back", ^ {
			
				[[returnedVC retain] autorelease];
				
				void (^dismissBlock)(void) = objc_getAssociatedObject(returnedVC, kDismissBlock);
				
				if (dismissBlock) {
					[[UIApplication sharedApplication] beginIgnoringInteractionEvents];			
					dismissBlock();
					objc_setAssociatedObject(returnedVC, kDismissBlock, nil, OBJC_ASSOCIATION_ASSIGN);
					[[UIApplication sharedApplication] endIgnoringInteractionEvents];
				}

			});

			return returnedVC;
		
		})());
		
		WANavigationController *enqueuedNavController = ((^ {
		
			__block WANavigationController *navController;
			if ([shownArticleVC isKindOfClass:[WAArticleViewController class]]) {
				navController = [(WAArticleViewController *)shownArticleVC wrappingNavController];
			} else {
				navController = [[[WAFauxRootNavigationController alloc] initWithRootViewController:shownArticleVC] autorelease];
			}
			
			navController.onViewDidLoad = ^ (WANavigationController *self) {
				((WANavigationBar *)self.navigationBar).backgroundView = [WANavigationBar defaultPatternBackgroundView];
			};
			
			if ([navController isViewLoaded])
			if (navController.onViewDidLoad)
				navController.onViewDidLoad(navController);
			
			return navController;
		
		})());

		__block void (^presentBlock)(void) = nil;
		__block void (^dismissBlock)(void) = nil;
		
		
		//	SHARED STUFF
		
		UIWindow *containingWindow = self.navigationController.view.window;
		CGAffineTransform containingWindowTransform = containingWindow.rootViewController.view.transform;
		CGRect containingWindowBounds = CGRectApplyAffineTransform(containingWindow.bounds, containingWindowTransform);		

		UIView *containerView = [[[UIView alloc] initWithFrame:containingWindowBounds] autorelease];
		containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		containerView.center = irCGRectAnchor(containingWindow.bounds, irCenter, YES);
		containerView.transform = containingWindowTransform;
		
		switch (animation) {

			case WAArticleContextAnimationFadeAndZoom: {
		
				presentBlock = ^ {
				
					UIEdgeInsets const navBarSnapshotEdgeInsets = (UIEdgeInsets){ 0, 0, -12, 0 };
					
					CGRect navBarBounds = self.navigationController.navigationBar.bounds;
					navBarBounds = UIEdgeInsetsInsetRect(navBarBounds, navBarSnapshotEdgeInsets);
					CGRect navBarRectInWindow = [containingWindow convertRect:navBarBounds fromView:self.navigationController.navigationBar];
					UIImage *navBarSnapshot = [self.navigationController.navigationBar.layer irRenderedImageWithEdgeInsets:navBarSnapshotEdgeInsets];
					UIView *navBarSnapshotHolderView = [[[UIView alloc] initWithFrame:(CGRect){ CGPointZero, navBarSnapshot.size }] autorelease];
					navBarSnapshotHolderView.layer.contents = (id)navBarSnapshot.CGImage;
					
					self.navigationController.navigationBar.layer.opacity = 0;
					articleViewController.view.hidden = YES;
					
					containerView.layer.contents = (id)[self.navigationController.view.layer irRenderedImage].CGImage;
					containerView.layer.contentsGravity = kCAGravityResizeAspectFill;
					
					self.navigationController.navigationBar.layer.opacity = 1;
					articleViewController.view.hidden = NO;
					
					UIView *backgroundView, *scalingHolderView;
					
					backgroundView = [[[UIView alloc] initWithFrame:containerView.bounds] autorelease];
					backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
					backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
					[containerView addSubview:backgroundView];
					
					scalingHolderView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
					[containerView addSubview:scalingHolderView];
					
					CGRect discreteArticleViewRectInWindow = [containingWindow convertRect:articleViewController.view.bounds fromView:articleViewController.view];
					UIView *discreteArticleSnapshotHolderView = [articleViewController.view irRenderedProxyView];
					discreteArticleSnapshotHolderView.frame = (CGRect){ CGPointZero, discreteArticleSnapshotHolderView.bounds.size };
					discreteArticleSnapshotHolderView.layer.contentsGravity = kCAGravityResize;
					[scalingHolderView addSubview:discreteArticleSnapshotHolderView];
					
					[self.navigationController presentModalViewController:enqueuedNavController animated:NO];
					[shownArticleVC setContextControlsVisible:NO animated:NO];
					
					UIImage *fullsizeArticleViewSnapshot = [enqueuedNavController.view.layer irRenderedImage];
					UIView *fullsizeArticleSnapshotHolderView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
					fullsizeArticleSnapshotHolderView.frame = (CGRect){ CGPointZero, fullsizeArticleViewSnapshot.size };
					fullsizeArticleSnapshotHolderView.layer.contents = (id)fullsizeArticleViewSnapshot.CGImage;
					fullsizeArticleSnapshotHolderView.layer.contentsGravity = kCAGravityResize;
					[scalingHolderView addSubview:fullsizeArticleSnapshotHolderView];
					
					discreteArticleSnapshotHolderView.frame = scalingHolderView.bounds;
					discreteArticleSnapshotHolderView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
					fullsizeArticleSnapshotHolderView.frame = scalingHolderView.bounds;
					fullsizeArticleSnapshotHolderView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
					
					[containingWindow addSubview:containerView];
					
					[containerView addSubview:navBarSnapshotHolderView];
					navBarSnapshotHolderView.frame = [containingWindow convertRect:navBarRectInWindow toView:navBarSnapshotHolderView.superview];
					
					backgroundView.alpha = 0;
					discreteArticleSnapshotHolderView.alpha = 1;
					fullsizeArticleSnapshotHolderView.alpha = 0;
					scalingHolderView.frame = [containingWindow convertRect:discreteArticleViewRectInWindow toView:scalingHolderView.superview];
					scalingHolderView.layer.borderWidth = 1;
					scalingHolderView.layer.borderColor = [UIColor redColor].CGColor;
					
					UIViewAnimationOptions animationOptions = UIViewAnimationOptionCurveEaseInOut;
					
					[UIView animateWithDuration:0.35 * 10 delay:0 options:animationOptions animations: ^ {
					
						backgroundView.alpha = 1;
						fullsizeArticleSnapshotHolderView.alpha = 1;
						scalingHolderView.frame = (CGRect){ CGPointZero, fullsizeArticleViewSnapshot.size };
						
					} completion: ^ (BOOL finished) {
					
						[[UIApplication sharedApplication] endIgnoringInteractionEvents];
						
						[containerView removeFromSuperview];

						if ([shownArticleVC conformsToProtocol:@protocol(WAArticleViewControllerPresenting)])
							[(id<WAArticleViewControllerPresenting>)shownArticleVC setContextControlsVisible:YES animated:NO];
						
						[shownArticleVC.view.window.layer addAnimation:((^{
							CATransition *transition = [CATransition animation];
							transition.type = kCATransitionFade;
							transition.removedOnCompletion = YES;
							transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
							transition.duration = 0.35f;
							return transition;
						})()) forKey:kCATransition];

					}];
				
				};
				
				dismissBlock = ^ {
				
					IRCATransact(^{
						
						[shownArticleVC dismissModalViewControllerAnimated:NO];
						
						[[UIApplication sharedApplication].keyWindow.layer addAnimation:((^{
							CATransition *transition = [CATransition animation];
							transition.type = kCATransitionFade;
							transition.removedOnCompletion = YES;
							transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
							transition.duration = 0.3f;
							return transition;
						})()) forKey:kCATransition];

					});
				
				};
							
				break;
				
			}

			case WAArticleContextAnimationCoverVertically: {
			
				__block UIWindow *containerWindow = nil;
				
				__block UIView *backgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
				backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
				backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];				
				
				__block UIView *contextView = nil;
			
				presentBlock = ^ {
				
					[enqueuedNavController setNavigationBarHidden:YES animated:NO];
					
					NSMutableArray *preconditions = [NSMutableArray array];
					NSMutableArray *animations = [NSMutableArray array];
					NSMutableArray *postconditions = [NSMutableArray array];
					
					[containingWindow.rootViewController.view addSubview:containerView];
					containerView.transform = CGAffineTransformIdentity;
					containerView.frame = containerView.superview.bounds;
					
					backgroundView.frame = containerView.bounds;
					[containerView addSubview:backgroundView];
					[preconditions irEnqueueBlock:^{
						backgroundView.alpha = 0;
					}];
					[animations irEnqueueBlock:^{
						backgroundView.alpha = 1;
					}];
					
					CGRect contextRect = IRCGRectAlignToRect((CGRect){
						CGPointZero,
						(CGSize){
							CGRectGetWidth(containerView.bounds) - 48,
							CGRectGetHeight(containerView.bounds) - 48
						}
					}, containerView.bounds, irBottom, YES);
					
					CGRect fromContextRect = CGRectOffset(containerView.bounds, 0, CGRectGetHeight(containerView.bounds));
					CGRect toContextRect = containerView.bounds;
					
					[containerView addSubview:(contextView = enqueuedNavController.view)];
					contextView.frame = toContextRect;
					contextView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
					[contextView layoutSubviews];
					[preconditions irEnqueueBlock:^{
						contextView.frame = fromContextRect;
					}];
					[animations irEnqueueBlock:^{
						contextView.frame = toContextRect;
					}];
					
					
					[shownArticleVC view];
					shownArticleVC.view.backgroundColor = [UIColor clearColor];
					
					if ([shownArticleVC respondsToSelector:@selector(handlePreferredInterfaceRect:)])
						[shownArticleVC handlePreferredInterfaceRect:contextRect];
					
					[preconditions irExecuteAllObjectsAsBlocks];
					[UIView animateWithDuration:0.5f delay:0 options:0 animations:^{
						
						[animations irExecuteAllObjectsAsBlocks];
						
					} completion: ^ (BOOL finished) {
						
						[postconditions irExecuteAllObjectsAsBlocks];
						[[UIApplication sharedApplication] endIgnoringInteractionEvents];
						
						[CATransaction begin];
						
						[[containerView retain] autorelease];
						[containerView removeFromSuperview];
						[enqueuedNavController.view removeFromSuperview];
						
						UIScreen *usedScreen = [UIApplication sharedApplication].keyWindow.screen;
						if (!usedScreen)
							usedScreen = [UIScreen mainScreen];
					
						__block WAGestureWindow *usedWindow = [[[WAGestureWindow alloc] initWithFrame:usedScreen.bounds] autorelease];
						usedWindow.backgroundColor = backgroundView.backgroundColor;
						usedWindow.opaque = NO;
						usedWindow.rootViewController = enqueuedNavController;
						
						usedWindow.onTap = ^ {
							
							void (^dismissBlock)(void) = objc_getAssociatedObject(shownArticleVC, kDismissBlock);
							
							if (dismissBlock)
								dismissBlock();
							
							usedWindow.onTap = nil;
							
						};
						
						usedWindow.onGestureRecognizeShouldReceiveTouch = ^ (UIGestureRecognizer *recognizer, UITouch *touch) {
						
							if (shownArticleVC.modalViewController)
								return NO;
							
							if (shownArticleVC.navigationController.modalViewController)
								return NO;
							
							if ([shownArticleVC.navigationController.viewControllers containsObject:shownArticleVC])
							if (shownArticleVC.navigationController.topViewController != shownArticleVC)
								return NO;
						
							CGPoint locationInShownArticleVC = [touch locationInView:shownArticleVC.view];
							
							if ([shownArticleVC respondsToSelector:@selector(isPointInsideInterfaceRect:)])
								return (BOOL)![shownArticleVC isPointInsideInterfaceRect:locationInShownArticleVC];
							
							return NO;
						
						};
						
						[usedWindow makeKeyAndVisible];
						[usedWindow retain];
						
						[CATransaction commit];
					
						containerWindow = usedWindow;
						
					}];
				
				};
				
				dismissBlock = ^ {
					
					[containerWindow resignKeyWindow];
					[containerWindow autorelease];
				
				};
			
				break;
				
			}

			default: {
				NSParameterAssert(NO);
				break;
			}
			
		}

		objc_setAssociatedObject(shownArticleVC, kDismissBlock, [[dismissBlock copy] autorelease], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		presentBlock();
	
	});
	
}

- (void) dealloc {

	[self.paginationSlider irUnbind:@"currentPage"];
	[self.paginatedView irRemoveObserverBlocksForKeyPath:@"currentPage"];
	
	[paginationSlider release];
	[paginatedView release];
	[discreteLayoutManager release];
	[discreteLayoutResult release];
	[layoutGrids release];
	
	[paginatedArticlesViewController release];
	
	[lastReadingProgressAnnotation release];
	[lastReadingProgressAnnotationView release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[paginationSliderSlot release];
	[super dealloc];

}

@end
