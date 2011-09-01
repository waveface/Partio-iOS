//
//  WADiscretePaginatedArticlesViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/31/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WADiscretePaginatedArticlesViewController.h"
#import "IRDiscreteLayoutManager.h"
#import "IRPaginatedView.h"
#import "WADataStore.h"

#import "WAArticleViewController.h"


static NSString * const kWADiscreteArticlePageElements = @"kWADiscreteArticlePageElements";

static NSString * const kWADiscreteArticleViewControllerOnItem = @"kWADiscreteArticleViewControllerOnItem";

@interface WADiscretePaginatedArticlesViewController () <IRDiscreteLayoutManagerDelegate, IRDiscreteLayoutManagerDataSource, IRPaginatedViewDelegate, WAArticleViewControllerPresenting>

@property (nonatomic, readwrite, retain) IRDiscreteLayoutManager *discreteLayoutManager;
@property (nonatomic, readwrite, retain) IRDiscreteLayoutResult *discreteLayoutResult;
@property (nonatomic, readwrite, retain) NSArray *layoutGrids;
@property (nonatomic, readwrite, retain) IRPaginatedView *paginatedView;

- (UIView *) representingViewForItem:(WAArticle *)anArticle;
- (void) adjustPageViewAtIndex:(NSUInteger)anIndex;

@end

@implementation WADiscretePaginatedArticlesViewController
@synthesize discreteLayoutManager, discreteLayoutResult, layoutGrids, paginatedView;

- (void) loadView {

	NSLog(@"TBD remember previous paginated view page");

	self.view = [[[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame] autorelease];
	self.view.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
	
	self.paginatedView = [[[IRPaginatedView alloc] initWithFrame:self.view.bounds] autorelease];
	self.paginatedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.paginatedView.delegate = self;
	[self.view addSubview:self.paginatedView];
	
	if (self.discreteLayoutResult)
		[self.paginatedView reloadViews];
	
}

- (UIView *) representingViewForItem:(WAArticle *)anArticle {

	__block __typeof__(self) nrSelf = self;

	WAArticleViewController *articleViewController = nil;
	
	articleViewController = objc_getAssociatedObject(anArticle, &kWADiscreteArticleViewControllerOnItem);
	
	if (!articleViewController) {
		articleViewController = [WAArticleViewController controllerRepresentingArticle:[[anArticle objectID] URIRepresentation]];
		articleViewController.presentationStyle = WAArticleViewControllerPresentationFullFrame;
		objc_setAssociatedObject(anArticle, &kWADiscreteArticleViewControllerOnItem, articleViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	articleViewController.view.clipsToBounds = YES;
	articleViewController.view.layer.borderColor = [UIColor colorWithWhite:0.9f alpha:1.0f].CGColor;
	articleViewController.view.layer.borderWidth = 1.0f;
	
	articleViewController.onPresentingViewController = ^ (void(^action)(UIViewController <WAArticleViewControllerPresenting> *parentViewController)) {
	
		action(nrSelf);
	
	};
	
	return articleViewController.view;
	
}

- (void) setContextControlsVisible:(BOOL)contextControlsVisible animated:(BOOL)animated {

	NSLog(@"TBD %s", __PRETTY_FUNCTION__);

}

- (IRDiscreteLayoutManager *) discreteLayoutManager {

	if (discreteLayoutManager)
		return discreteLayoutManager;
		
	__block __typeof__(self) nrSelf = self;
		
	IRDiscreteLayoutGridAreaDisplayBlock genericDisplayBlock = [[^ (IRDiscreteLayoutGrid *self, id anItem) {
	
		if (![anItem isKindOfClass:[WAArticle class]])
			return nil;
	
		return [nrSelf representingViewForItem:(WAArticle *)anItem];
	
	} copy] autorelease];
	
	IRDiscreteLayoutGrid *portraitGrid = [IRDiscreteLayoutGrid prototype];
	[portraitGrid registerLayoutAreaNamed:@"A" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
	[portraitGrid registerLayoutAreaNamed:@"B" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
	[portraitGrid registerLayoutAreaNamed:@"C" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 0, 1, 2) displayBlock:genericDisplayBlock];
	[portraitGrid registerLayoutAreaNamed:@"D" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 2, 2, 1) displayBlock:genericDisplayBlock];
	
	IRDiscreteLayoutGrid *landscapeGrid = [IRDiscreteLayoutGrid prototype];
	[landscapeGrid registerLayoutAreaNamed:@"A" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
	[landscapeGrid registerLayoutAreaNamed:@"B" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
	[landscapeGrid registerLayoutAreaNamed:@"C" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 1, 0, 1, 2) displayBlock:genericDisplayBlock];
	[landscapeGrid registerLayoutAreaNamed:@"D" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 0, 1, 2) displayBlock:genericDisplayBlock];
	
	portraitGrid.contentSize = (CGSize){ 768, 1024 };
	landscapeGrid.contentSize = (CGSize){ 1024, 768 };
	
	[IRDiscreteLayoutGrid markAreaNamed:@"A" inGridPrototype:portraitGrid asEquivalentToAreaNamed:@"A" inGridPrototype:landscapeGrid];
	[IRDiscreteLayoutGrid markAreaNamed:@"B" inGridPrototype:portraitGrid asEquivalentToAreaNamed:@"B" inGridPrototype:landscapeGrid];
	[IRDiscreteLayoutGrid markAreaNamed:@"C" inGridPrototype:portraitGrid asEquivalentToAreaNamed:@"C" inGridPrototype:landscapeGrid];
	[IRDiscreteLayoutGrid markAreaNamed:@"D" inGridPrototype:portraitGrid asEquivalentToAreaNamed:@"D" inGridPrototype:landscapeGrid];
	
	//	Since we only want one of the landscape / portrait grids to be visible, don’t use both in the array
	
	self.layoutGrids = [NSArray arrayWithObjects:
		(UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? portraitGrid : landscapeGrid),
	nil];
	
	self.discreteLayoutManager = [[IRDiscreteLayoutManager new] autorelease];
	self.discreteLayoutManager.delegate = self;
	self.discreteLayoutManager.dataSource = self;
	return self.discreteLayoutManager;

}

- (void) viewDidUnload {

	self.discreteLayoutManager = nil;
	self.discreteLayoutResult = nil;
	[super viewDidUnload];

}

-	(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	
	return YES;
	
}

- (void) reloadViewContents {
	
	if (!self.discreteLayoutResult)
		self.discreteLayoutResult = [self.discreteLayoutManager calculatedResult];
	
	[self.paginatedView reloadViews];

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
	
	IRDiscreteLayoutGrid *viewGrid = (IRDiscreteLayoutGrid *)[self.discreteLayoutResult.grids objectAtIndex:index];
	
	NSMutableArray *pageElements = [NSMutableArray arrayWithCapacity:[viewGrid.layoutAreaNames count]];
	
	viewGrid.contentSize = aPaginatedView.frame.size;
	
	[viewGrid enumerateLayoutAreasWithBlock: ^ (NSString *name, id item, BOOL(^validatorBlock)(IRDiscreteLayoutGrid *self, id anItem), CGRect(^layoutBlock)(IRDiscreteLayoutGrid *self, id anItem), id(^displayBlock)(IRDiscreteLayoutGrid *self, id anItem)) {
	
		UIView *placedSubview = (UIView *)displayBlock(viewGrid, item);
		NSParameterAssert(placedSubview);
		placedSubview.frame = layoutBlock(viewGrid, item);
		[pageElements addObject:placedSubview];
		[returnedView addSubview:placedSubview];
		
	}];
	
	objc_setAssociatedObject(returnedView, &kWADiscreteArticlePageElements, pageElements, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
			
	return returnedView;

}

- (UIViewController *) viewControllerForSubviewAtIndex:(NSUInteger)index inPaginatedView:(IRPaginatedView *)paginatedView {

	return nil;

}

- (void) adjustPageViewAtIndex:(NSUInteger)anIndex {

	UIView *currentPageView = [self.paginatedView existingPageAtIndex:anIndex];	
	NSArray *currentPageElements = objc_getAssociatedObject(currentPageView, &kWADiscreteArticlePageElements);
	IRDiscreteLayoutGrid *currentPageGrid = [self.discreteLayoutResult.grids objectAtIndex:anIndex];
	
	NSSet *allDestinations = [currentPageGrid allTransformablePrototypeDestinations];
	
	//	Find the best grid alternative in allDestinations, and then enumerate its layout areas, using the provided layout blocks to relayout all the element representing views in the current paginated view page.
	
	if ([allDestinations count] != 1) {
		currentPageGrid.contentSize = self.view.bounds.size;
		[currentPageGrid enumerateLayoutAreasWithBlock:^(NSString *name, id item, BOOL(^validatorBlock)(IRDiscreteLayoutGrid *self, id anItem), CGRect(^layoutBlock)(IRDiscreteLayoutGrid *self, id anItem), id(^displayBlock)(IRDiscreteLayoutGrid *self, id anItem)) {
			((UIView *)[currentPageElements objectAtIndex:[currentPageGrid.layoutAreaNames indexOfObject:name]]).frame = layoutBlock(currentPageGrid, item);
		}];
		return;
	}
	
	
	//	Assume that grid transforms are 1-to-1
	
	if ([allDestinations count] != 1)
		return;
		
	IRDiscreteLayoutGrid *transformedGrid = [allDestinations anyObject];
	transformedGrid = [currentPageGrid transformedGridWithPrototype:(transformedGrid.prototype ? transformedGrid.prototype : transformedGrid)];
	
	transformedGrid.contentSize = self.view.bounds.size;
	
	[[currentPageGrid retain] autorelease];
	
	[[self.discreteLayoutResult mutableArrayValueForKey:@"grids"] replaceObjectAtIndex:anIndex withObject:transformedGrid];
	
	[transformedGrid enumerateLayoutAreasWithBlock: ^ (NSString *name, id item, BOOL(^validatorBlock)(IRDiscreteLayoutGrid *self, id anItem), CGRect(^layoutBlock)(IRDiscreteLayoutGrid *self, id anItem), id(^displayBlock)(IRDiscreteLayoutGrid *self, id anItem)) {
	
		((UIView *)[currentPageElements objectAtIndex:[currentPageGrid.layoutAreaNames indexOfObject:name]]).frame = layoutBlock(transformedGrid, item);
		
	}];

}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];

	[CATransaction begin];
	[CATransaction setDisableActions:YES];

	//	If the paginated view is currently showing a view constructed with information provided by a layout grid, and that layout grid’s prototype has a fully transformable target, grab that transformable prototype and do a transform, then reposition individual items
	
	if (self.paginatedView.currentPage > 0)
		[self adjustPageViewAtIndex:(self.paginatedView.currentPage - 1)];
	
	[self adjustPageViewAtIndex:self.paginatedView.currentPage];
	
	if ((self.paginatedView.currentPage + 1) < self.paginatedView.numberOfPages) {
		[self adjustPageViewAtIndex:(self.paginatedView.currentPage + 1)];
	}
	
	[CATransaction commit];
	
}

- (void) dealloc {

	[discreteLayoutManager release];

	[super dealloc];

}

@end
