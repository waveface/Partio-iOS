//
//  WAOverviewController+ContextPresenting.m
//  wammer
//
//  Created by Evadne Wu on 2/29/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAOverviewController+ContextPresenting.h"
#import "WAArticleViewController.h"
#import "WADataStore.h"
#import "WAFauxRootNavigationController.h"
#import "WANavigationBar.h"
#import "WAButton.h"
#import "IRTransparentToolbar.h"
#import "WAStackedArticleViewController.h"
#import "IRSlidingSplitViewController.h"

NSString * const kPresentedArticle = @"WAOverviewController_presentedArticle";


@interface WAOverviewController (ContextPresenting_Private)

- (void(^)(void)) dismissBlockForArticleContextViewController:(WAArticleViewController *)controller;
- (void) setDismissBlock:(void(^)(void))aBlock forArticleContextViewController:(WAArticleViewController *)controller;

@end


@implementation WAOverviewController (ContextPresenting)

- (WAArticle *) presentedArticle {

	return [self irAssociatedObjectWithKey:&kPresentedArticle];

}

- (void) setPresentedArticle:(WAArticle *)presentedArticle {

	[self irAssociateObject:presentedArticle usingKey:&kPresentedArticle policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC changingObservedKey:nil];
	
}

- (WAArticleViewController *) presentDetailedContextForArticle:(WAArticle *)article {

	__weak IRSlidingSplitViewController *rootSSVC = (IRSlidingSplitViewController *)self.navigationController.parentViewController;
	NSCParameterAssert([rootSSVC isKindOfClass:[IRSlidingSplitViewController class]]);
	
	UIApplication * const app = [UIApplication sharedApplication];
	[app beginIgnoringInteractionEvents];
	
	self.presentedArticle = article;
	
	WAArticleViewController *shownArticleVC = [self newContextViewControllerForArticle:article];
	shownArticleVC.hostingViewController = self;
	
	UINavigationController *enqueuedNavController = [self wrappingNavigationControllerForContextViewController:shownArticleVC];
	
	[rootSSVC setShowingMasterViewController:YES animated:YES completion:^(BOOL didFinish) {

		[rootSSVC setDetailViewController:enqueuedNavController animated:NO completion:^(BOOL didFinish) {
			
			[rootSSVC setShowingMasterViewController:NO animated:YES completion:^(BOOL didFinish) {
			
				[app endIgnoringInteractionEvents];
				
			}];
			
		}];
		
	}];
	
	return shownArticleVC;

}

- (void) dismissArticleContextViewController:(WAArticleViewController *)controller {

	__weak IRSlidingSplitViewController *rootSSVC = (IRSlidingSplitViewController *)self.navigationController.parentViewController;
	NSCParameterAssert([rootSSVC isKindOfClass:[IRSlidingSplitViewController class]]);
	
	UIApplication * const app = [UIApplication sharedApplication];
	[app beginIgnoringInteractionEvents];
	
	[rootSSVC setShowingMasterViewController:YES animated:YES completion:^(BOOL didFinish) {
	
		[rootSSVC setDetailViewController:nil animated:NO completion:^(BOOL didFinish) {
		
			[app endIgnoringInteractionEvents];
			
		}];
		
	}];

}

- (WAArticleViewController *) newContextViewControllerForArticle:(WAArticle *)article {

	WAArticleStyle style = WAFullScreenArticleStyle|WASuggestedStyleForArticle(article);
	WAArticleViewController *articleVC	= [WAArticleViewController controllerForArticle:article style:style];
	articleVC.hostingViewController = self;
	
	__weak WAOverviewController *wSelf = self;
	__weak WAArticleViewController *wArticleVC = articleVC;
	__weak WAStackedArticleViewController *wStackedArticleVC = [articleVC isKindOfClass:[WAStackedArticleViewController class]] ? (WAStackedArticleViewController *)articleVC : nil;
	
	wStackedArticleVC.onViewDidLoad = (void(^)(WAArticleViewController *, UIView *)) ^ (WAStackedArticleViewController *self, UIView *ownView) {
	
		IRCATransact(^{
		
			self.view.backgroundColor = [UIColor clearColor];
			[self.navigationController.view layoutSubviews];
			
			CGRect interfaceRect = self.view.bounds;
			interfaceRect = CGRectInset(interfaceRect, 24.0f, 0.0f);
			
			[self handlePreferredInterfaceRect:interfaceRect];
			
			__block void (^poke)(UIView *) = ^ (UIView *aView) {
			
				[aView layoutSubviews];
				
				for (UIView *aSubview in aView.subviews)
					poke(aSubview);
				
			};
			
			poke(self.view);
			poke = nil;
		
		});							
	
	};
	
	if ([wStackedArticleVC isViewLoaded])
		wStackedArticleVC.onViewDidLoad(wStackedArticleVC, wStackedArticleVC.view);
	
	wStackedArticleVC.onPullTop = ^ (UIScrollView *aSV) {
		
		[aSV setContentOffset:aSV.contentOffset animated:NO];
		[wSelf dismissArticleContextViewController:wStackedArticleVC];
		
	};
	
	wStackedArticleVC.headerView = ((^ {
		
		IRView *enclosingView = [[IRView alloc] initWithFrame:(CGRect){ CGPointZero, (CGSize){ 64, 64 }}];
		
		enclosingView.opaque = NO;
								
		CGRect toolbarRect = UIEdgeInsetsInsetRect(enclosingView.bounds, (UIEdgeInsets){ 0, 0, 0, 0 });
		toolbarRect.size.height = 44;
		
		UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:toolbarRect];
		__weak UIToolbar *wToolbar = toolbar;
		[enclosingView addSubview:toolbar];
		
		toolbar.backgroundColor = [UIColor colorWithWhite:245.0/255.0 alpha:1];
		
		UIImage *toolbarBackground = [[UIImage imageNamed:@"WAArticleStackHeaderBarBackground"] resizableImageWithCapInsets:UIEdgeInsetsZero];
		UIImage *toolbarBackgroundLandscapePhone = [[UIImage imageNamed:@"WAArticleStackHeaderBarBackgroundLandscapePhone"] resizableImageWithCapInsets:UIEdgeInsetsZero];
		
		NSCParameterAssert(toolbarBackground);
		NSCParameterAssert(toolbarBackgroundLandscapePhone);
		
		[toolbar setBackgroundImage:toolbarBackground forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
		[toolbar setBackgroundImage:toolbarBackgroundLandscapePhone forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsLandscapePhone];
						
		toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
		toolbar.items = wStackedArticleVC.headerBarButtonItems;
		
		enclosingView.onLayoutSubviews = ^ {
		
			[wToolbar layoutSubviews];
		
		};
		
		WAButton *closeButton = [WAButton buttonWithType:UIButtonTypeCustom];
		[enclosingView addSubview:closeButton];
		[closeButton setImage:[UIImage imageNamed:@"WACornerCloseButton"] forState:UIControlStateNormal];
		[closeButton setImage:[UIImage imageNamed:@"WACornerCloseButtonActive"] forState:UIControlStateHighlighted];
		[closeButton setImage:[UIImage imageNamed:@"WACornerCloseButtonActive"] forState:UIControlStateSelected];
		closeButton.frame = enclosingView.bounds;
		closeButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
		
		__weak WAButton *wCloseButton = closeButton;
		
		closeButton.action = ^ {
		
			[wSelf dismissArticleContextViewController:wArticleVC];
			wCloseButton.action = nil;
		
		};
		
		return enclosingView;
									
	})());
	

	
	
	
	
	
	
	
	UINavigationItem *navItem = articleVC.navigationItem;
	
	if (!navItem.leftBarButtonItem) {
		
		navItem.hidesBackButton = NO;
		navItem.leftBarButtonItem = WABackBarButtonItem(nil, @"Back", ^ {

			[wSelf dismissArticleContextViewController:wArticleVC];

		});
	
	}

	return articleVC;

}

- (UINavigationController *) wrappingNavigationControllerForContextViewController:(WAArticleViewController *)controller {
	
	WANavigationController *returnedNavC = nil;
	
	if ([controller isKindOfClass:[WAArticleViewController class]]) {
	
		returnedNavC = [[WANavigationController alloc] initWithRootViewController:controller];
		
	} else {

		returnedNavC = [[WAFauxRootNavigationController alloc] initWithRootViewController:controller];
		
	}
	
	returnedNavC.onViewDidLoad = ^ (WANavigationController *self) {
		((WANavigationBar *)self.navigationBar).customBackgroundView = [WANavigationBar defaultPatternBackgroundView];
	};
	
	if ([returnedNavC isViewLoaded])
	if (returnedNavC.onViewDidLoad)
		returnedNavC.onViewDidLoad(returnedNavC);
	
	[returnedNavC setNavigationBarHidden:YES animated:NO];
	
	return returnedNavC;

}

@end


@implementation WAOverviewController (ContextPresenting_Private)

NSString * const kWAOverviewController_ContextPresenting_Private_DismissBlock = @"WAOverviewController_ContextPresenting_Private_DismissBlock";

- (void(^)(void)) dismissBlockForArticleContextViewController:(WAArticleViewController *)controller {

	return objc_getAssociatedObject(controller, &kWAOverviewController_ContextPresenting_Private_DismissBlock);

}

- (void) setDismissBlock:(void(^)(void))aBlock forArticleContextViewController:(WAArticleViewController *)controller {

	if (aBlock == [self dismissBlockForArticleContextViewController:controller])
		return;

	objc_setAssociatedObject(controller, &kWAOverviewController_ContextPresenting_Private_DismissBlock, aBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);

}

@end
