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
	
	return [articleViewController retain];

}

- (WAArticleViewController *) cachedArticleViewControllerForArticle:(WAArticle *)article {

	WAArticleViewController *cachedVC = [self.articleViewControllersCache objectForKey:article];
	if (cachedVC)
		return cachedVC;
	
	WAArticleViewController *createdVC = [[self newDiscreteArticleViewControllerForArticle:article] autorelease];
	[self.articleViewControllersCache setObject:createdVC forKey:article];
	
	return createdVC;

}

- (void) removeCachedArticleViewControllers {

	[self.articleViewControllersCache removeAllObjects];

}

- (UIView *) newPageContainerView {

	WAView *returnedView = [[[WAView alloc] initWithFrame:(CGRect){ CGPointZero, (CGSize){ 320, 320 } }] autorelease];
	returnedView.autoresizingMask = UIViewAutoresizingNone;
	returnedView.clipsToBounds = NO;
	returnedView.layer.shouldRasterize = YES;
	
	__block UIView *backdropView = [[[UIView alloc] initWithFrame:CGRectInset(returnedView.bounds, -12, -12)] autorelease];
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
	
	//	CGRect (^shadowRect)(CGSize, IRAnchor) = ^ (CGSize shadowImageSize, IRAnchor anchor) {
	//	
	//		return IRCGRectAlignToRect((CGRect){
	//			CGPointZero,
	//			(CGSize){
	//				shadowImageSize.width,
	//				MIN(shadowImageSize.height, CGRectGetHeight(backdropView.bounds))
	//			}
	//		}, backdropView.bounds, anchor, YES);
	//	
	//	};
	//	
	//	UIImage *leftShadow = [UIImage imageNamed:@"WAPageShadowLeft"];
	//	UIImage *rightShadow = [UIImage imageNamed:@"WAPageShadowRight"];
	//	UIImageView *leftShadowView = nil, *rightShadowView = nil;
	//	
	//	[backdropView addSubview:(rightShadowView = [[[UIImageView alloc] initWithImage:rightShadow] autorelease])];
	//	rightShadowView.frame = CGRectOffset(shadowRect(rightShadow.size, irRight), rightShadow.size.width, 0);
	//	rightShadowView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleHeight;
	//	rightShadowView.alpha = 0.5;
	//	
	//	[backdropView addSubview:(leftShadowView = [[[UIImageView alloc] initWithImage:leftShadow] autorelease])];
	//	leftShadowView.frame = CGRectOffset(shadowRect(leftShadow.size, irLeft), -1.0f * leftShadow.size.width, 0);
	//	leftShadowView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleHeight;
	//	leftShadowView.alpha = 0.5;
	
	return [returnedView retain];

}

- (NSArray *) newLayoutGrids {

	__block __typeof__(self) nrSelf = self;
		
	IRDiscreteLayoutGridAreaDisplayBlock genericDisplayBlock = [[^ (IRDiscreteLayoutGrid *self, id anItem) {
	
		if (![anItem isKindOfClass:[WAArticle class]])
			return nil;
	
		return [nrSelf representingViewForItem:(WAArticle *)anItem];
	
	} copy] autorelease];
	
	NSMutableArray *enqueuedLayoutGrids = [NSMutableArray array];
	CGSize portraitSize = (CGSize){ 768, 1024 };
	CGSize landscapeSize = (CGSize){ 1024, 768 };
	
	IRDiscreteLayoutGrid *gridA = [IRDiscreteLayoutGrid prototype];
	gridA.contentSize = portraitSize;
	[gridA registerLayoutAreaNamed:@"A" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridA registerLayoutAreaNamed:@"B" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridA registerLayoutAreaNamed:@"C" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridA registerLayoutAreaNamed:@"D" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridA registerLayoutAreaNamed:@"E" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 2, 1, 1) displayBlock:genericDisplayBlock];
	[gridA registerLayoutAreaNamed:@"F" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 2, 1, 1) displayBlock:genericDisplayBlock];
	
	IRDiscreteLayoutGrid *gridA_H = [IRDiscreteLayoutGrid prototype];
	gridA_H.contentSize = landscapeSize;
	[gridA_H registerLayoutAreaNamed:@"A" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridA_H registerLayoutAreaNamed:@"B" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridA_H registerLayoutAreaNamed:@"C" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 1, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridA_H registerLayoutAreaNamed:@"D" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 1, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridA_H registerLayoutAreaNamed:@"E" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridA_H registerLayoutAreaNamed:@"F" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 1, 1, 1) displayBlock:genericDisplayBlock];
	
	[[gridA class] markAreaNamed:@"A" inGridPrototype:gridA asEquivalentToAreaNamed:@"A" inGridPrototype:gridA_H];
	[[gridA class] markAreaNamed:@"B" inGridPrototype:gridA asEquivalentToAreaNamed:@"B" inGridPrototype:gridA_H];
	[[gridA class] markAreaNamed:@"C" inGridPrototype:gridA asEquivalentToAreaNamed:@"C" inGridPrototype:gridA_H];
	[[gridA class] markAreaNamed:@"D" inGridPrototype:gridA asEquivalentToAreaNamed:@"D" inGridPrototype:gridA_H];
	[[gridA class] markAreaNamed:@"E" inGridPrototype:gridA asEquivalentToAreaNamed:@"E" inGridPrototype:gridA_H];
	[[gridA class] markAreaNamed:@"F" inGridPrototype:gridA asEquivalentToAreaNamed:@"F" inGridPrototype:gridA_H];

	IRDiscreteLayoutGrid *gridB = [IRDiscreteLayoutGrid prototype];
	gridB.contentSize = portraitSize;
	[gridB registerLayoutAreaNamed:@"A" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 0, 1, 1) displayBlock:genericDisplayBlock];	
	[gridB registerLayoutAreaNamed:@"B" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridB registerLayoutAreaNamed:@"C" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 2, 1, 1) displayBlock:genericDisplayBlock];
	[gridB registerLayoutAreaNamed:@"D" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 0, 1, 2) displayBlock:genericDisplayBlock];
	[gridB registerLayoutAreaNamed:@"E" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 2, 1, 1) displayBlock:genericDisplayBlock];
	
	IRDiscreteLayoutGrid *gridB_H = [IRDiscreteLayoutGrid prototype];
	gridB_H.contentSize = landscapeSize;
	[gridB_H registerLayoutAreaNamed:@"A" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 0, 1, 1) displayBlock:genericDisplayBlock];	
	[gridB_H registerLayoutAreaNamed:@"B" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 1, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridB_H registerLayoutAreaNamed:@"C" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridB_H registerLayoutAreaNamed:@"D" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 1, 2, 1) displayBlock:genericDisplayBlock];
	[gridB_H registerLayoutAreaNamed:@"E" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 1, 1, 1) displayBlock:genericDisplayBlock];
	
	[[gridB class] markAreaNamed:@"A" inGridPrototype:gridB asEquivalentToAreaNamed:@"A" inGridPrototype:gridB_H];
	[[gridB class] markAreaNamed:@"B" inGridPrototype:gridB asEquivalentToAreaNamed:@"B" inGridPrototype:gridB_H];
	[[gridB class] markAreaNamed:@"C" inGridPrototype:gridB asEquivalentToAreaNamed:@"C" inGridPrototype:gridB_H];
	[[gridB class] markAreaNamed:@"D" inGridPrototype:gridB asEquivalentToAreaNamed:@"D" inGridPrototype:gridB_H];
	[[gridB class] markAreaNamed:@"E" inGridPrototype:gridB asEquivalentToAreaNamed:@"E" inGridPrototype:gridB_H];
	
	IRDiscreteLayoutGrid *gridC = [IRDiscreteLayoutGrid prototype];
	gridC.contentSize = portraitSize;
	[gridC registerLayoutAreaNamed:@"A" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 0, 1, 2) displayBlock:genericDisplayBlock];
	[gridC registerLayoutAreaNamed:@"B" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 0, 2, 1, 1) displayBlock:genericDisplayBlock];
	[gridC registerLayoutAreaNamed:@"C" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 0, 1, 1) displayBlock:genericDisplayBlock];	
	[gridC registerLayoutAreaNamed:@"D" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridC registerLayoutAreaNamed:@"E" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(2, 3, 1, 2, 1, 1) displayBlock:genericDisplayBlock];
	
	IRDiscreteLayoutGrid *gridC_H = [IRDiscreteLayoutGrid prototype];
	gridC_H.contentSize = landscapeSize;
	[gridC_H registerLayoutAreaNamed:@"A" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 0, 2, 1) displayBlock:genericDisplayBlock];
	[gridC_H registerLayoutAreaNamed:@"B" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 0, 1, 1) displayBlock:genericDisplayBlock];
	[gridC_H registerLayoutAreaNamed:@"C" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 0, 1, 1, 1) displayBlock:genericDisplayBlock];	
	[gridC_H registerLayoutAreaNamed:@"D" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 1, 1, 1, 1) displayBlock:genericDisplayBlock];
	[gridC_H registerLayoutAreaNamed:@"E" validatorBlock:nil layoutBlock:IRDiscreteLayoutGridAreaLayoutBlockForProportionsMake(3, 2, 2, 1, 1, 1) displayBlock:genericDisplayBlock];
	
	[[gridC class] markAreaNamed:@"A" inGridPrototype:gridC asEquivalentToAreaNamed:@"A" inGridPrototype:gridC_H];
	[[gridC class] markAreaNamed:@"B" inGridPrototype:gridC asEquivalentToAreaNamed:@"B" inGridPrototype:gridC_H];
	[[gridC class] markAreaNamed:@"C" inGridPrototype:gridC asEquivalentToAreaNamed:@"C" inGridPrototype:gridC_H];
	[[gridC class] markAreaNamed:@"D" inGridPrototype:gridC asEquivalentToAreaNamed:@"D" inGridPrototype:gridC_H];
	[[gridC class] markAreaNamed:@"E" inGridPrototype:gridC asEquivalentToAreaNamed:@"E" inGridPrototype:gridC_H];
	
	[enqueuedLayoutGrids addObject:gridA];
	[enqueuedLayoutGrids addObject:gridB];
	[enqueuedLayoutGrids addObject:gridC];
	
	return [enqueuedLayoutGrids retain];

}

@end


@implementation WADiscretePaginatedArticlesViewController (DiscreteLayout_Private)

- (NSCache *) articleViewControllersCache {

	static NSString * key = @"WADiscretePaginatedArticlesViewController_DiscreteLayout_Private_articleViewControllersCache";
	
	NSCache *currentCache = objc_getAssociatedObject(self, &key);
	if (currentCache)
		return currentCache;
	
	NSCache *cache = [[[NSCache alloc] init] autorelease];
	objc_setAssociatedObject(self, &key, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	return cache;

}

@end
