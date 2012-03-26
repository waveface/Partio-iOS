//
//  WADiscretePaginatedArticlesViewController+ContextPresenting.m
//  wammer
//
//  Created by Evadne Wu on 2/29/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADiscretePaginatedArticlesViewController+ContextPresenting.h"
#import "WAArticleViewController.h"
#import "WADataStore.h"
#import "WAFauxRootNavigationController.h"
#import "WANavigationBar.h"
#import "WAButton.h"
#import "WAGestureWindow.h"
#import "IRTransparentToolbar.h"

#define USES_PAGINATED_CONTEXT 0

@interface WADiscretePaginatedArticlesViewController (ContextPresenting_Private)

- (void(^)(void)) dismissBlockForArticleContextViewController:(UIViewController<WAArticleViewControllerPresenting> *)controller;

- (void) setDismissBlock:(void(^)(void))aBlock forArticleContextViewController:(UIViewController<WAArticleViewControllerPresenting> *)controller;

@end


@implementation WADiscretePaginatedArticlesViewController (ContextPresenting)

- (UIViewController<WAArticleViewControllerPresenting> *) presentDetailedContextForArticle:(NSURL *)anObjectURI {

	return [self presentDetailedContextForArticle:anObjectURI animated:YES];

}

- (UIViewController<WAArticleViewControllerPresenting> *) presentDetailedContextForArticle:(NSURL *)anObjectURI animated:(BOOL)animated {

	BOOL usesFlip = [[NSUserDefaults standardUserDefaults] boolForKey:kWADebugUsesDiscreteArticleFlip];
	
	WAArticleContextAnimation animation = WAArticleContextAnimationDefault;
	
	if (!animated) {
		animation = WAArticleContextAnimationNone;
	} else if (usesFlip) {
		animation = WAArticleContextAnimationFlipAndScale;
	} else {
		animation = WAArticleContextAnimationCoverVertically;
	}

	return [self presentDetailedContextForArticle:anObjectURI usingAnimation:animation];

}

- (UIViewController<WAArticleViewControllerPresenting> *) presentDetailedContextForArticle:(NSURL *)articleURI usingAnimation:(WAArticleContextAnimation)animation {

	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	__block WAArticle *article = (WAArticle *)[self.managedObjectContext irManagedObjectForURI:articleURI];
	__block WADiscretePaginatedArticlesViewController *nrSelf = self;
	__block WAArticleViewController *articleViewController = [self cachedArticleViewControllerForArticle:article];
		
	__block UIViewController<WAArticleViewControllerPresenting> *shownArticleVC = [self newContextViewControllerForArticle:articleURI];
	
	UINavigationController *enqueuedNavController = [self wrappingNavigationControllerForContextViewController:shownArticleVC];
	
	__block void (^presentBlock)(void) = nil;
	__block void (^dismissBlock)(void) = nil;
	
	UIWindow * const containingWindow = self.navigationController.view.window;
	CGAffineTransform const containingWindowTransform = containingWindow.rootViewController.view.transform;
	CGRect const containingWindowBounds = CGRectApplyAffineTransform(containingWindow.bounds, containingWindowTransform);
	
	UIView *containerView = [[UIView alloc] initWithFrame:containingWindowBounds];
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
				UIView *navBarSnapshotHolderView = [[UIView alloc] initWithFrame:(CGRect){ CGPointZero, navBarSnapshot.size }];
				navBarSnapshotHolderView.layer.contents = (id)navBarSnapshot.CGImage;
				
				self.navigationController.navigationBar.layer.opacity = 0;
				articleViewController.view.hidden = YES;
				
				containerView.layer.contents = (id)[self.navigationController.view.layer irRenderedImage].CGImage;
				containerView.layer.contentsGravity = kCAGravityResizeAspectFill;
				
				self.navigationController.navigationBar.layer.opacity = 1;
				articleViewController.view.hidden = NO;
				
				UIView *backgroundView, *scalingHolderView;
				
				backgroundView = [[UIView alloc] initWithFrame:containerView.bounds];
				backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
				backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
				[containerView addSubview:backgroundView];
				
				scalingHolderView = [[UIView alloc] initWithFrame:CGRectZero];
				[containerView addSubview:scalingHolderView];
				
				CGRect discreteArticleViewRectInWindow = [containingWindow convertRect:articleViewController.view.bounds fromView:articleViewController.view];
				UIView *discreteArticleSnapshotHolderView = [articleViewController.view irRenderedProxyView];
				discreteArticleSnapshotHolderView.frame = (CGRect){ CGPointZero, discreteArticleSnapshotHolderView.bounds.size };
				discreteArticleSnapshotHolderView.layer.contentsGravity = kCAGravityResize;
				[scalingHolderView addSubview:discreteArticleSnapshotHolderView];
				
				[self.navigationController presentModalViewController:enqueuedNavController animated:NO];
				[shownArticleVC setContextControlsVisible:NO animated:NO];
				
				UIImage *fullsizeArticleViewSnapshot = [enqueuedNavController.view.layer irRenderedImage];
				UIView *fullsizeArticleSnapshotHolderView = [[UIView alloc] initWithFrame:CGRectZero];
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
		
			__block UIWindow *currentKeyWindow = [UIApplication sharedApplication].keyWindow;
			__block WAGestureWindow *containerWindow = nil;
			
			UIColor *backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
			
			presentBlock = ^ {
			
				UIScreen *usedScreen = [UIApplication sharedApplication].keyWindow.screen;
				if (!usedScreen)
					usedScreen = [UIScreen mainScreen];
				
				containerWindow = [[WAGestureWindow alloc] initWithFrame:usedScreen.bounds];
				containerWindow.backgroundColor = backgroundColor;
				containerWindow.opaque = NO;
				containerWindow.rootViewController = enqueuedNavController;
				
				containerWindow.onTap = ^ {
					
					[nrSelf dismissArticleContextViewController:shownArticleVC];
					containerWindow.onTap = nil;
					
				};
				
				containerWindow.onGestureRecognizeShouldReceiveTouch = ^ (UIGestureRecognizer *recognizer, UITouch *touch) {
				
					if (shownArticleVC.modalViewController)
						return NO;
					
					UINavigationController *navC = shownArticleVC.navigationController;
					
					if (navC) {
					
						if (navC.modalViewController)
							return NO;
					
						if (!navC.navigationBarHidden)
						if (CGRectContainsPoint(navC.navigationBar.bounds, [touch locationInView:navC.navigationBar]))
							return NO;
						
						if (!navC.toolbarHidden)
						if (CGRectContainsPoint(navC.toolbar.bounds, [touch locationInView:navC.toolbar]))
							return NO;
					
					}
					
					//		if ([shownArticleVC.navigationController.viewControllers containsObject:shownArticleVC])
					//		if (shownArticleVC.navigationController.topViewController != shownArticleVC)
					//			return NO;
				
					CGPoint locationInShownArticleVC = [touch locationInView:shownArticleVC.view];
					
					if ([shownArticleVC respondsToSelector:@selector(isPointInsideInterfaceRect:)])
						return (BOOL)![shownArticleVC isPointInsideInterfaceRect:locationInShownArticleVC];
					
					return NO;
				
				};
				
				[enqueuedNavController setNavigationBarHidden:YES animated:NO];
				
				if ([shownArticleVC respondsToSelector:@selector(handlePreferredInterfaceRect:)]) {
				
					__block __typeof__(enqueuedNavController) nrEnqueuedNavController = enqueuedNavController;
					//	__block __typeof__(containerView) nrContainerView = containerView;
				
					void (^onViewDidLoad)() = ^ {
					
						IRCATransact(^{
						
							shownArticleVC.view.backgroundColor = [UIColor clearColor];
							[nrEnqueuedNavController.view layoutSubviews];
							
							[shownArticleVC handlePreferredInterfaceRect:IRCGRectAlignToRect((CGRect){
								CGPointZero,
								(CGSize){
									CGRectGetWidth(shownArticleVC.view.bounds) - 0,
									CGRectGetHeight(shownArticleVC.view.bounds) - 0
								}
							}, shownArticleVC.view.bounds, irBottom, YES)];
							
							__block void (^poke)(UIView *) = ^ (UIView *aView) {
							
								[aView layoutSubviews];
								
								for (UIView *aSubview in aView.subviews)
									poke(aSubview);
								
							};
							
							poke(shownArticleVC.view);
						
						});							
					
					};
					
					if ([shownArticleVC respondsToSelector:@selector(setOnViewDidLoad:)])
						[shownArticleVC performSelector:@selector(setOnViewDidLoad:) withObject:(id)onViewDidLoad];
					
					if ([shownArticleVC isViewLoaded])
						onViewDidLoad();
					
				}
				
				if ([shownArticleVC respondsToSelector:@selector(setOnPullTop:)]) {
					
					[shownArticleVC performSelector:@selector(setOnPullTop:) withObject:(id)(^ (UIScrollView *aSV){
					
						[aSV setContentOffset:aSV.contentOffset animated:NO];
						[nrSelf dismissArticleContextViewController:shownArticleVC];
						
					})];
					
				}
				
				if ([shownArticleVC respondsToSelector:@selector(setHeaderView:)]) {
				
					[shownArticleVC performSelector:@selector(setHeaderView:) withObject:((^ {
					
						WAView *enclosingView = [[WAView alloc] initWithFrame:(CGRect){ CGPointZero, (CGSize){ 64, 64 }}];
												
						CGRect toolbarRect = UIEdgeInsetsInsetRect(enclosingView.bounds, (UIEdgeInsets){ 0, 28, 0, 0 });
						toolbarRect.size.height = 44;
						
						__block UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:toolbarRect];
						[enclosingView addSubview:toolbar];
						
						toolbar.backgroundColor = [UIColor colorWithWhite:245.0/255.0 alpha:1];
						
						UIImage *toolbarBackground = [[UIImage imageNamed:@"WAArticleStackHeaderBarBackground"] resizableImageWithCapInsets:UIEdgeInsetsZero];
						UIImage *toolbarBackgroundLandscapePhone = [[UIImage imageNamed:@"WAArticleStackHeaderBarBackgroundLandscapePhone"] resizableImageWithCapInsets:UIEdgeInsetsZero];
						[toolbar setBackgroundImage:toolbarBackground forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
						[toolbar setBackgroundImage:toolbarBackgroundLandscapePhone forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsLandscapePhone];
						
						toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
						
						toolbar.items = ((^ {
						
							if ([shownArticleVC respondsToSelector:@selector(headerBarButtonItems)])
								return (NSArray *)[shownArticleVC performSelector:@selector(headerBarButtonItems)];
						
							NSMutableArray *items = [NSMutableArray array];
							UINavigationItem *navItem = shownArticleVC.navigationItem;
							
							if (navItem.leftBarButtonItems)
								[items addObjectsFromArray:shownArticleVC.navigationItem.leftBarButtonItems];
							
							[items addObject:[IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemFlexibleSpace wiredAction:nil]];

							if (navItem.rightBarButtonItems)
								[items addObjectsFromArray:shownArticleVC.navigationItem.rightBarButtonItems];
							
							return (NSArray *)items;
						
						})());
						
						enclosingView.onLayoutSubviews = ^ {
						
							[toolbar layoutSubviews];
						
						};
						
						__block WAButton *nrCloseButton = [WAButton buttonWithType:UIButtonTypeCustom];
						[enclosingView addSubview:nrCloseButton];
						[nrCloseButton setImage:[UIImage imageNamed:@"WACornerCloseButton"] forState:UIControlStateNormal];
						[nrCloseButton setImage:[UIImage imageNamed:@"WACornerCloseButtonActive"] forState:UIControlStateHighlighted];
						[nrCloseButton setImage:[UIImage imageNamed:@"WACornerCloseButtonActive"] forState:UIControlStateSelected];
						nrCloseButton.frame = enclosingView.bounds;
						nrCloseButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
						nrCloseButton.action = ^ {
						
							[nrSelf dismissArticleContextViewController:shownArticleVC];
							nrCloseButton.action = nil;
						
						};
						
						return enclosingView;
													
					})())];
				
				}
				
				[[UIApplication sharedApplication] endIgnoringInteractionEvents];
				
				[CATransaction begin];
				
				[containerWindow makeKeyAndVisible];
				
				UIViewAnimationOptions animationOptions = UIViewAnimationOptionCurveEaseInOut;
				
				UIView *rootView = containerWindow.rootViewController.view;
				CGRect toFrame = rootView.frame;
				CGRect fromFrame = rootView.frame = [rootView.superview convertRect:CGRectOffset(rootView.bounds, 0, CGRectGetHeight(rootView.bounds)) fromView:rootView];
				
				UIColor *fromBackgroundColor = [UIColor clearColor];
				UIColor *toBackgroundColor = containerWindow.backgroundColor;
								
				containerWindow.backgroundColor = fromBackgroundColor;
				containerWindow.rootViewController.view.frame = fromFrame;
				
				[UIView animateWithDuration:0.35 delay:0 options:animationOptions animations:^{
				
					containerWindow.backgroundColor = toBackgroundColor;
					containerWindow.rootViewController.view.frame = toFrame;
				
				} completion:nil];
				
				[CATransaction commit];
					
			};
			
			dismissBlock = ^ {
			
				UIView *rootView = containerWindow.rootViewController.view;
				NSParameterAssert(rootView);
				
				UIViewAnimationOptions animationOptions = UIViewAnimationOptionCurveEaseInOut;
				
				[UIView animateWithDuration:0.35 delay:0 options:animationOptions animations:^{
				
					rootView.frame = [rootView.superview convertRect:CGRectOffset(rootView.bounds, 0, CGRectGetHeight(rootView.bounds)) fromView:rootView];
					containerWindow.backgroundColor = nil;
					
				} completion:^(BOOL finished) {
				
					@autoreleasepool {
							
						containerWindow.rootViewController = nil;
						
					}
				
					containerWindow.hidden = YES;
					containerWindow.userInteractionEnabled = NO;
					
					[containerWindow resignKeyWindow];
					containerWindow = nil;
					
					//	Potentially smoofy
					
					NSArray *allCurrentWindows = [UIApplication sharedApplication].windows;
					__block BOOL hasFoundCapturedKeyWindow = NO;
					
					[allCurrentWindows enumerateObjectsUsingBlock: ^ (UIWindow *aWindow, NSUInteger idx, BOOL *stop) {
					
						if (aWindow == currentKeyWindow) {
							[aWindow makeKeyAndVisible];
							hasFoundCapturedKeyWindow = YES;
							*stop = YES;
							return;
						}
						
						if (!hasFoundCapturedKeyWindow)
						if (idx == ([allCurrentWindows count] - 1))
							[[allCurrentWindows objectAtIndex:0] becomeKeyWindow];
						
					}];
					
				}];
			
			};
		
			break;
			
		}

		default: {
			NSParameterAssert(NO);
			break;
		}
		
	}

	[self setDismissBlock:dismissBlock forArticleContextViewController:shownArticleVC];
	
	presentBlock();

	return shownArticleVC;
	
}

- (void) dismissArticleContextViewController:(UIViewController<WAArticleViewControllerPresenting> *)controller {

	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	if ([controller respondsToSelector:@selector(article)]) {
		id representedArticle = [controller performSelector:@selector(article)];
		if ([representedArticle isKindOfClass:[WAArticle class]]) {
			[self.paginatedView scrollToPageAtIndex:[self gridIndexOfArticle:(WAArticle *)representedArticle] animated:NO];
		}
	}
	
	(([self dismissBlockForArticleContextViewController:controller])());
	[self setDismissBlock:nil forArticleContextViewController:controller];
	
	[[UIApplication sharedApplication] endIgnoringInteractionEvents];

}

- (UIViewController<WAArticleViewControllerPresenting> *) newContextViewControllerForArticle:(NSURL *)articleURI {

	__block __typeof__(self) nrSelf = self;
	__block UIViewController<WAArticleViewControllerPresenting> *returnedVC = nil;

	#if USES_PAGINATED_CONTEXT
		
		returnedVC = nrSelf.paginatedArticlesViewController;
		
		((WAPaginatedArticlesViewController *)returnedVC).context = [NSDictionary dictionaryWithObjectsAndKeys:
			articleURI, @"lastVisitedObjectURI",
		nil];

	#else
	
		WAArticleViewControllerPresentationStyle style = WAFullFrameArticleStyleFromDiscreteStyle([WAArticleViewController suggestedDiscreteStyleForArticle:(WAArticle *)[self.managedObjectContext irManagedObjectForURI:articleURI]]);

		returnedVC = [WAArticleViewController controllerForArticle:articleURI usingPresentationStyle:style];
		
		((WAArticleViewController *)returnedVC).onPresentingViewController = ^ (void(^action)(UIViewController <WAArticleViewControllerPresenting> *parentViewController)) {
			if ([returnedVC.navigationController conformsToProtocol:@protocol(WAArticleViewControllerPresenting)]) {
				action((UIViewController <WAArticleViewControllerPresenting> *)returnedVC.navigationController);
			} else {
				action((UIViewController <WAArticleViewControllerPresenting> *)nrSelf);
			}
		};
		
	#endif
	
	if (!returnedVC.navigationItem.leftBarButtonItem) {
				
		returnedVC.navigationItem.hidesBackButton = NO;
		returnedVC.navigationItem.leftBarButtonItem = WABackBarButtonItem(nil, @"Back", ^ {

			[nrSelf dismissArticleContextViewController:returnedVC];

		});
	
	}

	return returnedVC;

}

- (UINavigationController *) wrappingNavigationControllerForContextViewController:(UIViewController<WAArticleViewControllerPresenting> *)controller {
	
	WANavigationController *returnedNavC = nil;
	
	if ([controller isKindOfClass:[WAArticleViewController class]]) {
		
		returnedNavC = [(WAArticleViewController *)controller wrappingNavController];
		
	} else {

		returnedNavC = [[WAFauxRootNavigationController alloc] initWithRootViewController:controller];
		
	}
	
	returnedNavC.onViewDidLoad = ^ (WANavigationController *self) {
		((WANavigationBar *)self.navigationBar).customBackgroundView = [WANavigationBar defaultPatternBackgroundView];
	};
	
	if ([returnedNavC isViewLoaded])
	if (returnedNavC.onViewDidLoad)
		returnedNavC.onViewDidLoad(returnedNavC);
	
	return returnedNavC;

}

@end


@implementation WADiscretePaginatedArticlesViewController (ContextPresenting_Private)

NSString * const kWADiscretePaginatedArticlesViewController_ContextPresenting_Private_DismissBlock = @"WADiscretePaginatedArticlesViewController_ContextPresenting_Private_DismissBlock";

- (void(^)(void)) dismissBlockForArticleContextViewController:(UIViewController<WAArticleViewControllerPresenting> *)controller {

	return objc_getAssociatedObject(controller, &kWADiscretePaginatedArticlesViewController_ContextPresenting_Private_DismissBlock);

}

- (void) setDismissBlock:(void(^)(void))aBlock forArticleContextViewController:(UIViewController<WAArticleViewControllerPresenting> *)controller {

	if (aBlock == [self dismissBlockForArticleContextViewController:controller])
		return;

	objc_setAssociatedObject(controller, &kWADiscretePaginatedArticlesViewController_ContextPresenting_Private_DismissBlock, aBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);

}

@end
