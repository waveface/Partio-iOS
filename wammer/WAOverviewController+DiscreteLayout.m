//
//  WAOverviewController+DiscreteLayout.m
//  wammer
//
//  Created by Evadne Wu on 2/29/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAOverviewController+DiscreteLayout.h"
#import "WADataStore.h"
#import "WAArticleViewController.h"

#import "IRDiscreteLayoutManager.h"
#import "WAEightPartLayoutGrid.h"
#import "IRDiscreteLayoutGrid+Transforming.h"

#import "WADiscreteLayoutHelpers.h"

#import "WAArticle+DiscreteLayoutAdditions.h"


static NSString * const kLastUsedLayoutGrids = @"-[WAOverviewController(DiscreteLayout) lastUsedLayoutGrids]";


@interface WAOverviewController (DiscreteLayout_Private) <WAArticleViewControllerDelegate>

@property (nonatomic, readwrite, retain) IRDiscreteLayoutResult *discreteLayoutResult;
@property (nonatomic, readonly, retain) NSCache *articleViewControllersCache;

@end


@implementation WAOverviewController (DiscreteLayout)

- (NSArray *) lastUsedLayoutGrids {

	return objc_getAssociatedObject(self, &kLastUsedLayoutGrids);

}

- (void) setLastUsedLayoutGrids:(NSArray *)newGrids {

	if ([self lastUsedLayoutGrids] == newGrids)
		return;
	
	objc_setAssociatedObject(self, &kLastUsedLayoutGrids, newGrids, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

}

- (WAArticleViewController *) newDiscreteArticleViewControllerForArticle:(WAArticle *)article NS_RETURNS_RETAINED {

	__weak WAOverviewController *wSelf = self;
	
	WAArticleViewControllerPresentationStyle style = [WAArticleViewController suggestedDiscreteStyleForArticle:article];
	WAArticleViewController *articleViewController = [WAArticleViewController controllerForArticle:article context:article.managedObjectContext presentationStyle:style];
	
	articleViewController.onViewDidLoad = ^ (WAArticleViewController *loadedVC, UIView *loadedView) {
		
		UIView *borderView = [[UIView alloc] initWithFrame:CGRectInset(loadedVC.view.bounds, 0, 0)];
		borderView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		borderView.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1].CGColor;
		borderView.layer.borderWidth = 1;
		
		[loadedVC.view addSubview:borderView];
		[borderView.superview sendSubviewToBack:borderView];
		
	};
	
	articleViewController.hostingViewController = self;
	
	articleViewController.onViewTap = ^ {
	
		[wSelf presentDetailedContextForArticle:[[articleViewController.article objectID] URIRepresentation]];
		
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
	
	return articleViewController;

}

- (WAArticleViewController *) cachedArticleViewControllerForArticle:(WAArticle *)article {

	NSValue *objectValue = [NSValue valueWithNonretainedObject:article];

	WAArticleViewController *cachedVC = [self.articleViewControllersCache objectForKey:objectValue];
	if (cachedVC)
		return cachedVC;
	
	WAArticleViewController *createdVC = [self newDiscreteArticleViewControllerForArticle:article];
	[self.articleViewControllersCache setObject:createdVC forKey:objectValue];
	
	return createdVC;

}

- (void) removeCachedArticleViewControllers {

	[self.articleViewControllersCache removeAllObjects];

}

- (UIView *) newPageContainerView {

	IRView *returnedView = [[IRView alloc] initWithFrame:(CGRect){ CGPointZero, (CGSize){ 320, 320 } }];
	returnedView.backgroundColor = nil;
	returnedView.opaque = NO;
	returnedView.autoresizingMask = UIViewAutoresizingNone;
	returnedView.clipsToBounds = YES;
	returnedView.layer.shouldRasterize = YES;
	returnedView.layer.rasterizationScale = [UIScreen mainScreen].scale;
	
	//	__block UIView *backdropView = [[UIView alloc] initWithFrame:CGRectInset(returnedView.bounds, -12, -12)];
	//	backdropView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	//	backdropView.layer.backgroundColor = [UIColor colorWithRed:245.0f/255.0f green:240.0f/255.0f blue:234.0f/255.0f alpha:1].CGColor;
	//	backdropView.layer.cornerRadius = 4;
	//	backdropView.layer.shadowOpacity = 0.35;
	//	backdropView.layer.shadowOffset = (CGSize){ 0, 2 };
	//	[returnedView addSubview:backdropView];
	//	
	//	returnedView.onLayoutSubviews = ^ {
	//	
	//		backdropView.layer.shadowPath = [UIBezierPath bezierPathWithRect:backdropView.bounds].CGPath;
	//	
	//	};
	
	[returnedView setNeedsLayout];
	
	return returnedView;

}

- (NSArray *) newLayoutGrids {

	NSArray *returnedArray = WADefaultLayoutGrids();
	
	__weak WAOverviewController *wSelf = self;
	
	IRDiscreteLayoutGridAreaDisplayBlock displayBlock = [ ^ (IRDiscreteLayoutGrid *self, id anItem) {
	
		NSCParameterAssert(wSelf);
		return [wSelf representingViewForItem:anItem];
	
	} copy];
	
	return [returnedArray irMap: ^ (IRDiscreteLayoutGrid *grid, NSUInteger index, BOOL *stop) {
	
		[grid enumerateLayoutAreaNamesWithBlock:^(NSString *anAreaName) {
		
			[grid setDisplayBlock:displayBlock forAreaNamed:anAreaName];
			
		}];
		
		return grid;
		
	}];

}

- (UIView *) representingViewForItem:(WAArticle *)anArticle {

	UIView *returnedView = [self cachedArticleViewControllerForArticle:anArticle].view;
	
	return returnedView;
	
}

- (NSString *) presentationTemplateNameForArticleViewController:(WAArticleViewController *)controller {

	WAArticle *article = controller.article;
	if (!article)
		return nil;
	
	IRDiscreteLayoutGrid *grid = [self.discreteLayoutResult gridContainingItem:article];
	NSString *prototypeName = grid.identifier;
	NSString *areaName = [grid layoutAreaNameForItem:article];
	
	if (!areaName)
		return nil;
	
	return @"WFPreviewTemplate_Discrete_Plaintext";

}

- (NSCache *) articleViewControllersCache {

	static NSString * key = @"WAOverviewController_DiscreteLayout_Private_articleViewControllersCache";
	
	NSCache *currentCache = objc_getAssociatedObject(self, &key);
	if (currentCache)
		return currentCache;
	
	NSCache *cache = [[NSCache alloc] init];
	objc_setAssociatedObject(self, &key, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	return cache;

}

@end
