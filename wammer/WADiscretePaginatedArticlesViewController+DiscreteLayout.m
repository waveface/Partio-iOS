//
//  WADiscretePaginatedArticlesViewController+DiscreteLayout.m
//  wammer
//
//  Created by Evadne Wu on 2/29/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADiscretePaginatedArticlesViewController+DiscreteLayout.h"
#import "WADataStore.h"
#import "WAArticleViewController.h"
#import "WAView.h"

#import "IRDiscreteLayoutManager.h"
#import "WAEightPartLayoutGrid.h"
#import "IRDiscreteLayoutGrid+Transforming.h"


static NSString * const kWADiscreteArticleViewControllerOnItem = @"kWADiscreteArticleViewControllerOnItem";
static NSString * const kWADiscreteArticlesViewLastUsedLayoutGrids = @"kWADiscreteArticlesViewLastUsedLayoutGrids";


@interface WADiscretePaginatedArticlesViewController (DiscreteLayout_Private)

@property (nonatomic, readonly, retain) NSCache *articleViewControllersCache;

@end


@implementation WADiscretePaginatedArticlesViewController (DiscreteLayout)

- (NSArray *) lastUsedLayoutGrids {

	return objc_getAssociatedObject(self, &kWADiscreteArticlesViewLastUsedLayoutGrids);

}

- (void) setLastUsedLayoutGrids:(NSArray *)newGrids {

	if ([self lastUsedLayoutGrids] == newGrids)
		return;
	
	objc_setAssociatedObject(self, &kWADiscreteArticlesViewLastUsedLayoutGrids, newGrids, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

}

- (WAArticleViewController *) newDiscreteArticleViewControllerForArticle:(WAArticle *)article NS_RETURNS_RETAINED {

	__block __typeof__(self) nrSelf = self;
	
	NSURL *objectURI = [[article objectID] URIRepresentation];
	
	WAArticleViewControllerPresentationStyle style = [WAArticleViewController suggestedDiscreteStyleForArticle:article];
	WAArticleViewController *articleViewController = [WAArticleViewController controllerForArticle:objectURI usingPresentationStyle:style];
	
	articleViewController.onViewDidLoad = ^ (WAArticleViewController *loadedVC, UIView *loadedView) {
		
		((UIView *)loadedVC.view.imageStackView).userInteractionEnabled = NO;
		
	};
	
	articleViewController.onPresentingViewController = ^ (void(^action)(UIViewController <WAArticleViewControllerPresenting> *parentViewController)) {
		
		action((UIViewController<WAArticleViewControllerPresenting> *)nrSelf);
		
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
	
//	NSString *identifier = articleViewController.article.identifier;
//	articleViewController.additionalDebugActions = [NSArray arrayWithObjects:
//	
//		[IRAction actionWithTitle:@"Make Last Read" block:^{
//		
//			nrSelf.lastReadObjectIdentifier = identifier;
//			[nrSelf updateLastReadingProgressAnnotation];
//		
//		}],
//		
//	nil];
	
	return articleViewController;

}

- (WAArticleViewController *) cachedArticleViewControllerForArticle:(WAArticle *)article {

	WAArticleViewController *cachedVC = [self.articleViewControllersCache objectForKey:article];
	if (cachedVC)
		return cachedVC;
	
	WAArticleViewController *createdVC = [self newDiscreteArticleViewControllerForArticle:article];
	[self.articleViewControllersCache setObject:createdVC forKey:article];
	
	return createdVC;

}

- (void) removeCachedArticleViewControllers {

	[self.articleViewControllersCache removeAllObjects];

}

- (UIView *) newPageContainerView {

	WAView *returnedView = [[WAView alloc] initWithFrame:(CGRect){ CGPointZero, (CGSize){ 320, 320 } }];
	returnedView.autoresizingMask = UIViewAutoresizingNone;
	returnedView.clipsToBounds = NO;
	returnedView.layer.shouldRasterize = YES;
	
	__block UIView *backdropView = [[UIView alloc] initWithFrame:CGRectInset(returnedView.bounds, -12, -12)];
	backdropView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	backdropView.layer.backgroundColor = [UIColor colorWithRed:245.0f/255.0f green:240.0f/255.0f blue:234.0f/255.0f alpha:1].CGColor;
	backdropView.layer.cornerRadius = 4;
	backdropView.layer.shadowOpacity = 0.35;
	backdropView.layer.shadowOffset = (CGSize){ 0, 2 };
	[returnedView addSubview:backdropView];
	
	returnedView.onLayoutSubviews = ^ {
	
		backdropView.layer.shadowPath = [UIBezierPath bezierPathWithRect:backdropView.bounds].CGPath;
	
	};
	
	[returnedView setNeedsLayout];
	
	return returnedView;

}

- (NSArray *) newLayoutGrids {

	__block __typeof__(self) nrSelf = self;
		
	IRDiscreteLayoutGridAreaDisplayBlock genericDisplayBlock = ^ (IRDiscreteLayoutGrid *self, id anItem) {
	
		if (![anItem isKindOfClass:[WAArticle class]])
			return (UIView *)nil;
	
		return [nrSelf representingViewForItem:(WAArticle *)anItem];
	
	};
	
	NSMutableArray *enqueuedLayoutGrids = [NSMutableArray array];
	CGSize portraitSize = (CGSize){ 768, 1024 };
	CGSize landscapeSize = (CGSize){ 1024, 768 };
	
	BOOL (^itemIsFavorite)(id<IRDiscreteLayoutItem>) = ^ (id<IRDiscreteLayoutItem> item) {
	
		if (![item isKindOfClass:[WAArticle class]])
			return NO;
		
		return [((WAArticle *)item).favorite isEqualToNumber:(id)kCFBooleanTrue];
	
	};
	
	IRDiscreteLayoutGridAreaValidatorBlock defaultNonFavoriteValidator = ^ (IRDiscreteLayoutGrid *self, id anItem) {
	
		return (BOOL)!itemIsFavorite(anItem);
	
	};
	
	IRDiscreteLayoutGridAreaValidatorBlock defaultFavoriteValidator = ^ (IRDiscreteLayoutGrid *self, id anItem) {
	
		return (BOOL)itemIsFavorite(anItem);
	
	};
	
	IRDiscreteLayoutGridAreaValidatorBlock comboValidator = ^ (IRDiscreteLayoutGrid *self, id anItem) {
	
		if (itemIsFavorite(anItem))
			return NO;
	
		return (BOOL)((WADiscreteLayoutItemHasLink(anItem) && WADiscreteLayoutItemHasLongText(anItem)) || WADiscreteLayoutItemHasImage(anItem));
	
	};
	
	IRDiscreteLayoutGrid *gridA = [IRDiscreteLayoutGrid prototype];
	gridA.contentSize = portraitSize;
	gridA.allowsPartialInstancePopulation = YES;
	[gridA registerLayoutAreaNamed:@"A" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridA registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridA registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridA registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridA registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 2, 1, 1) displayBlock:genericDisplayBlock];
	[gridA registerLayoutAreaNamed:@"F" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 2, 1, 1) displayBlock:genericDisplayBlock];
	
	IRDiscreteLayoutGrid *gridA_H = [IRDiscreteLayoutGrid prototype];
	gridA_H.contentSize = landscapeSize;
	gridA_H.allowsPartialInstancePopulation = YES;
	[gridA_H registerLayoutAreaNamed:@"A" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridA_H registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridA_H registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 1, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridA_H registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 1, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridA_H registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridA_H registerLayoutAreaNamed:@"F" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 1, 1, 1) displayBlock:genericDisplayBlock];
	
	[[gridA class] markAreaNamed:@"A" inGridPrototype:gridA asEquivalentToAreaNamed:@"A" inGridPrototype:gridA_H];
	[[gridA class] markAreaNamed:@"B" inGridPrototype:gridA asEquivalentToAreaNamed:@"B" inGridPrototype:gridA_H];
	[[gridA class] markAreaNamed:@"C" inGridPrototype:gridA asEquivalentToAreaNamed:@"C" inGridPrototype:gridA_H];
	[[gridA class] markAreaNamed:@"D" inGridPrototype:gridA asEquivalentToAreaNamed:@"D" inGridPrototype:gridA_H];
	[[gridA class] markAreaNamed:@"E" inGridPrototype:gridA asEquivalentToAreaNamed:@"E" inGridPrototype:gridA_H];
	[[gridA class] markAreaNamed:@"F" inGridPrototype:gridA asEquivalentToAreaNamed:@"F" inGridPrototype:gridA_H];

	IRDiscreteLayoutGrid *gridB = [IRDiscreteLayoutGrid prototype];
	gridB.contentSize = portraitSize;
	[gridB registerLayoutAreaNamed:@"A" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 0, 1, 1) displayBlock:genericDisplayBlock];	
	[gridB registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridB registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 2, 1, 1) displayBlock:genericDisplayBlock];
	[gridB registerLayoutAreaNamed:@"D" validatorBlock:comboValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 0, 1, 2) displayBlock:genericDisplayBlock];
	[gridB registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 2, 1, 1) displayBlock:genericDisplayBlock];
	
	IRDiscreteLayoutGrid *gridB_H = [IRDiscreteLayoutGrid prototype];
	gridB_H.contentSize = landscapeSize;
	[gridB_H registerLayoutAreaNamed:@"A" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 0, 1, 1) displayBlock:genericDisplayBlock];	
	[gridB_H registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 1, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridB_H registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridB_H registerLayoutAreaNamed:@"D" validatorBlock:comboValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 1, 2, 1) displayBlock:genericDisplayBlock];
	[gridB_H registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 1, 1, 1) displayBlock:genericDisplayBlock];
	
	[[gridB class] markAreaNamed:@"A" inGridPrototype:gridB asEquivalentToAreaNamed:@"A" inGridPrototype:gridB_H];
	[[gridB class] markAreaNamed:@"B" inGridPrototype:gridB asEquivalentToAreaNamed:@"B" inGridPrototype:gridB_H];
	[[gridB class] markAreaNamed:@"C" inGridPrototype:gridB asEquivalentToAreaNamed:@"C" inGridPrototype:gridB_H];
	[[gridB class] markAreaNamed:@"D" inGridPrototype:gridB asEquivalentToAreaNamed:@"D" inGridPrototype:gridB_H];
	[[gridB class] markAreaNamed:@"E" inGridPrototype:gridB asEquivalentToAreaNamed:@"E" inGridPrototype:gridB_H];
	
	IRDiscreteLayoutGrid *gridC = [IRDiscreteLayoutGrid prototype];
	gridC.contentSize = portraitSize;
	[gridC registerLayoutAreaNamed:@"A" validatorBlock:comboValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 0, 1, 2) displayBlock:genericDisplayBlock];
	[gridC registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 2, 1, 1) displayBlock:genericDisplayBlock];
	[gridC registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 0, 1, 1) displayBlock:genericDisplayBlock];	
	[gridC registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridC registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 2, 1, 1) displayBlock:genericDisplayBlock];
	
	IRDiscreteLayoutGrid *gridC_H = [IRDiscreteLayoutGrid prototype];
	gridC_H.contentSize = landscapeSize;
	[gridC_H registerLayoutAreaNamed:@"A" validatorBlock:comboValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 0, 2, 1) displayBlock:genericDisplayBlock];
	[gridC_H registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridC_H registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 1, 1, 1) displayBlock:genericDisplayBlock];	
	[gridC_H registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 1, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridC_H registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 1, 1, 1) displayBlock:genericDisplayBlock];
	
	[[gridC class] markAreaNamed:@"A" inGridPrototype:gridC asEquivalentToAreaNamed:@"A" inGridPrototype:gridC_H];
	[[gridC class] markAreaNamed:@"B" inGridPrototype:gridC asEquivalentToAreaNamed:@"B" inGridPrototype:gridC_H];
	[[gridC class] markAreaNamed:@"C" inGridPrototype:gridC asEquivalentToAreaNamed:@"C" inGridPrototype:gridC_H];
	[[gridC class] markAreaNamed:@"D" inGridPrototype:gridC asEquivalentToAreaNamed:@"D" inGridPrototype:gridC_H];
	[[gridC class] markAreaNamed:@"E" inGridPrototype:gridC asEquivalentToAreaNamed:@"E" inGridPrototype:gridC_H];
	
	IRDiscreteLayoutGrid *gridD = [IRDiscreteLayoutGrid prototype];
	gridD.contentSize = portraitSize;
	[gridD registerLayoutAreaNamed:@"A" validatorBlock:defaultFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 4, 0, 0, 2, 2) displayBlock:genericDisplayBlock];
	[gridD registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 4, 0, 2, 1, 1) displayBlock:genericDisplayBlock];
	[gridD registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 4, 1, 2, 1, 1) displayBlock:genericDisplayBlock];
	[gridD registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 4, 0, 3, 1, 1) displayBlock:genericDisplayBlock];
	[gridD registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 4, 1, 3, 1, 1) displayBlock:genericDisplayBlock];
	
	IRDiscreteLayoutGrid *gridD_H = [IRDiscreteLayoutGrid prototype];
	gridD_H.contentSize = landscapeSize;
	[gridD_H registerLayoutAreaNamed:@"A" validatorBlock:defaultFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(4, 2, 0, 0, 2, 2) displayBlock:genericDisplayBlock];
	[gridD_H registerLayoutAreaNamed:@"B" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(4, 2, 2, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridD_H registerLayoutAreaNamed:@"C" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(4, 2, 2, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridD_H registerLayoutAreaNamed:@"D" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(4, 2, 3, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridD_H registerLayoutAreaNamed:@"E" validatorBlock:defaultNonFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(4, 2, 3, 1, 1, 1) displayBlock:genericDisplayBlock];
	
	[[gridD class] markAreaNamed:@"A" inGridPrototype:gridD asEquivalentToAreaNamed:@"A" inGridPrototype:gridD_H];
	[[gridD class] markAreaNamed:@"B" inGridPrototype:gridD asEquivalentToAreaNamed:@"B" inGridPrototype:gridD_H];
	[[gridD class] markAreaNamed:@"C" inGridPrototype:gridD asEquivalentToAreaNamed:@"C" inGridPrototype:gridD_H];
	[[gridD class] markAreaNamed:@"D" inGridPrototype:gridD asEquivalentToAreaNamed:@"D" inGridPrototype:gridD_H];
	[[gridD class] markAreaNamed:@"E" inGridPrototype:gridD asEquivalentToAreaNamed:@"E" inGridPrototype:gridD_H];
	
	IRDiscreteLayoutGrid *gridE = [IRDiscreteLayoutGrid prototype];
	gridE.contentSize = portraitSize;
	gridE.allowsPartialInstancePopulation = YES;
	[gridE registerLayoutAreaNamed:@"A" validatorBlock:defaultFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(1, 2, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridE registerLayoutAreaNamed:@"B" validatorBlock:defaultFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(1, 2, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
		
	IRDiscreteLayoutGrid *gridE_H = [IRDiscreteLayoutGrid prototype];
	gridE_H.contentSize = landscapeSize;
	gridE_H.allowsPartialInstancePopulation = YES;
	[gridE_H registerLayoutAreaNamed:@"A" validatorBlock:defaultFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 1, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridE_H registerLayoutAreaNamed:@"B" validatorBlock:defaultFavoriteValidator layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 1, 1, 0, 1, 1) displayBlock:genericDisplayBlock];
	
	[[gridE class] markAreaNamed:@"A" inGridPrototype:gridE asEquivalentToAreaNamed:@"A" inGridPrototype:gridE_H];
	[[gridE class] markAreaNamed:@"B" inGridPrototype:gridE asEquivalentToAreaNamed:@"B" inGridPrototype:gridE_H];
	
	[enqueuedLayoutGrids addObject:gridA];
	[enqueuedLayoutGrids addObject:gridB];
	[enqueuedLayoutGrids addObject:gridC];
	[enqueuedLayoutGrids addObject:gridD];
	[enqueuedLayoutGrids addObject:gridE];
	
	return enqueuedLayoutGrids;

}

- (UIView *) representingViewForItem:(WAArticle *)anArticle {

	UIView *returnedView = [self cachedArticleViewControllerForArticle:anArticle].view;
	
	returnedView.layer.cornerRadius = 2;

	returnedView.layer.backgroundColor = [UIColor whiteColor].CGColor;
	returnedView.layer.masksToBounds = YES;
	
	returnedView.layer.borderWidth = 1;
	returnedView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.05].CGColor;
	
	return returnedView;
	
}

@end


@implementation WADiscretePaginatedArticlesViewController (DiscreteLayout_Private)

- (NSCache *) articleViewControllersCache {

	static NSString * key = @"WADiscretePaginatedArticlesViewController_DiscreteLayout_Private_articleViewControllersCache";
	
	NSCache *currentCache = objc_getAssociatedObject(self, &key);
	if (currentCache)
		return currentCache;
	
	NSCache *cache = [[NSCache alloc] init];
	objc_setAssociatedObject(self, &key, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	return cache;

}

@end
