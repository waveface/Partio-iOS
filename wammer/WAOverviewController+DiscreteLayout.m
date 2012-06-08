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

	WAArticleStyle style = WACellArticleStyle|WASuggestedStyleForArticle(article);
	WAArticleViewController *articleViewController = [WAArticleViewController controllerForArticle:article style:style];
	
	articleViewController.delegate = self;
	articleViewController.hostingViewController = self;
	articleViewController.delegate = self;
		
	return articleViewController;

}

- (void) articleViewControllerDidLoadView:(WAArticleViewController *)controller {

	UIView * const containerView = controller.view;
	UIView * const borderView = [[UIView alloc] initWithFrame:containerView.bounds];
	
	borderView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	borderView.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1].CGColor;
	borderView.layer.borderWidth = 1;
	
	[containerView addSubview:borderView];
	[containerView sendSubviewToBack:borderView];

}

- (void) articleViewController:(WAArticleViewController *)controller didReceiveTap:(UITapGestureRecognizer *)tapGR {

	[self presentDetailedContextForArticle:controller.article];
		
}

- (void) articleViewController:(WAArticleViewController *)controller didReceivePinch:(UIPinchGestureRecognizer *)pinchGR {

	if (pinchGR.state == UIGestureRecognizerStateChanged)
	if (pinchGR.scale > 1.05f)
	if (pinchGR.velocity > 1.05f) {
	
		NSArray *allGRs = controller.view.gestureRecognizers;
	
		for (UIGestureRecognizer *gestureRecognizer in allGRs)
			gestureRecognizer.enabled = NO;
			
		[self presentDetailedContextForArticle:controller.article];
		
		for (UIGestureRecognizer *gestureRecognizer in allGRs)
			gestureRecognizer.enabled = YES;
		
	}

}

- (WAArticleViewController *) cachedArticleViewControllerForArticle:(WAArticle *)article {

	NSValue *objectValue = [NSValue valueWithNonretainedObject:article];

	WAArticleViewController *cachedVC = [self.articleViewControllersCache objectForKey:objectValue];
	if (cachedVC)
		return cachedVC;
	
	WAArticleViewController *createdVC = [self newDiscreteArticleViewControllerForArticle:article];
	[self.articleViewControllersCache setObject:createdVC forKey:objectValue];
	[self addChildViewController:createdVC];
	
	return createdVC;

}

- (void) removeCachedArticleViewController:(WAArticleViewController *)aVC {

	NSCParameterAssert(self == aVC.parentViewController);
	[aVC removeFromParentViewController];
	
	NSValue *objectValue = [NSValue valueWithNonretainedObject:aVC.article];
	
	[self.articleViewControllersCache removeObjectForKey:objectValue];

}

- (void) removeCachedArticleViewControllers {

	[self.articleViewControllersCache removeAllObjects];

}

- (UIView *) newPageContainerView {

	IRView *returnedView = [[IRView alloc] initWithFrame:(CGRect){ CGPointZero, (CGSize){ 320, 320 } }];
	returnedView.backgroundColor = [UIColor colorWithWhite:242.0/256.0 alpha:1];
	returnedView.opaque = YES;
	returnedView.autoresizingMask = UIViewAutoresizingNone;
	returnedView.clipsToBounds = YES;
	
	[returnedView setNeedsLayout];
	
	return returnedView;

}

- (NSArray *) newLayoutGrids {

	NSArray *grids = WADefaultLayoutGrids();
	
	__weak WAOverviewController *wSelf = self;
	
	IRDiscreteLayoutAreaDisplayBlock displayBlock = ^ (IRDiscreteLayoutArea *self, id anItem) {
	
		return [wSelf representingViewForItem:anItem];
	
	};
	
	for (IRDiscreteLayoutGrid *grid in grids)
		for (IRDiscreteLayoutArea *area in grid.layoutAreas)
			area.displayBlock = displayBlock;
	
	return grids;
	
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
	grid = [grid transformedGridWithPrototype:[grid bestCounteprartPrototypeForAspectRatio:[self currentAspectRatio]]];
	
	WADiscreteLayoutArea *area = (WADiscreteLayoutArea *)[grid areaForItem:article];
	NSParameterAssert([area isKindOfClass:[WADiscreteLayoutArea class]]);
	
	if (area.templateNameBlock) {
		NSString *answer = area.templateNameBlock(area);
		return answer;
	}
	
	return nil;

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
