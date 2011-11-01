//
//  WACompositionViewController+CustomUI.m
//  wammer
//
//  Created by Evadne Wu on 11/1/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WACompositionViewController+CustomUI.h"
#import "IRBarButtonItem.h"
#import "IRBindings.h"

#import "WADefines.h"

#import "WANavigationBar.h"
#import "WANavigationController.h"


@implementation WACompositionViewController (CustomUI)

- (UINavigationController *) wrappingNavigationController {

	NSAssert2(!self.navigationController, @"%@ must not have been put within another navigation controller when %@ is invoked.", self, NSStringFromSelector(_cmd));
	NSAssert2((UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()), @"%@: %s is not supported on this device.", self, NSStringFromSelector(_cmd));
	
	WANavigationController *navController = [[[WANavigationController alloc] initWithRootViewController:[[[UIViewController alloc] init] autorelease]] autorelease];
	
	NSKeyedUnarchiver *unarchiver = [[[NSKeyedUnarchiver alloc] initForReadingWithData:[NSKeyedArchiver archivedDataWithRootObject:navController]] autorelease];
	[unarchiver setClass:[WANavigationBar class] forClassName:@"UINavigationBar"];
	navController = [unarchiver decodeObjectForKey:@"root"];
	
	static NSString * const kViewControllerActionOnPop = @"waCompositionViewController_wrappingNavigationController_viewControllerActionOnPop";

	navController.willPushViewControllerAnimated = ^ (WANavigationController *self, UIViewController *pushedVC, BOOL animated) {
		
		if (![pushedVC isKindOfClass:[WACompositionViewController class]])
			return;
		
		((WACompositionViewController *)pushedVC).usesTransparentBackground = YES;
		
		UIBarButtonItem *oldLeftItem = pushedVC.navigationItem.leftBarButtonItem;
		UIBarButtonItem *oldRightItem = pushedVC.navigationItem.rightBarButtonItem;
		
		__block id leftTarget = oldLeftItem.target;
		__block SEL leftAction = oldLeftItem.action;
		
		__block id rightTarget = oldRightItem.target;
		__block SEL rightAction = oldRightItem.action;
		
		__block IRBarButtonItem *newLeftItem = WABackBarButtonItem(@"Cancel", ^{
			[leftTarget performSelector:leftAction withObject:newLeftItem];
		});
		
		__block IRBarButtonItem *newRightItem = WAStandardBarButtonItem(@"Done", ^{
			[rightTarget performSelector:rightAction withObject:newRightItem];
		});
		
		pushedVC.navigationItem.leftBarButtonItem = newLeftItem;		
		pushedVC.navigationItem.rightBarButtonItem = newRightItem;
		
		if (!pushedVC.navigationItem.titleView) {
			
			__block UILabel *titleLabel = [[[UILabel alloc] init] autorelease];
			titleLabel.textColor = [UIColor colorWithWhite:0.35 alpha:1];
			titleLabel.font = [UIFont fontWithName:@"Sansus Webissimo" size:24.0f];
			titleLabel.shadowColor = [UIColor whiteColor];
			titleLabel.shadowOffset = (CGSize){ 0, 1 };
			titleLabel.opaque = NO;
			titleLabel.backgroundColor = nil;
			
			[titleLabel irBind:@"text" toObject:pushedVC keyPath:@"title" options:[NSDictionary dictionaryWithObjectsAndKeys:
				
				[[^ (id oldValue, id newValue, NSString *changeType) {
					
					titleLabel.text = newValue;
					[titleLabel sizeToFit];
					
					return newValue;
				
				} copy] autorelease], kIRBindingsValueTransformerBlock,
				
				kCFBooleanTrue, kIRBindingsAssignOnMainThreadOption,
			
			nil]];
			
			objc_setAssociatedObject(pushedVC, &kViewControllerActionOnPop, ^ {
			
				[titleLabel irUnbind:@"text"];
			
			}, OBJC_ASSOCIATION_COPY_NONATOMIC);
			
			pushedVC.navigationItem.titleView = titleLabel;

		}
		
		if (![pushedVC isViewLoaded])
			return;
			
		pushedVC.view.backgroundColor = nil;
		pushedVC.view.opaque = NO;
		
	};
	
	navController.onDismissModalViewControllerAnimated = ^ (WANavigationController *self, BOOL animated) {
	
		void (^action)() = objc_getAssociatedObject(self.topViewController, &kViewControllerActionOnPop);
		if (action)
				action();
		
	};
	
	[navController initWithRootViewController:self];
	
	navController.onViewDidLoad = ^ (WANavigationController *self) {
		
		((WANavigationBar *)self.navigationBar).backgroundView = [WANavigationBar defaultGradientBackgroundView];
		
		self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPatternWoodTexture"]];
		
		UIColor *baseColor = [UIColor colorWithRed:.75 green:.65 blue:.52 alpha:1];
		
		IRGradientView *gradientView = [[[IRGradientView alloc] initWithFrame:(CGRect){ CGPointZero, (CGSize){ CGRectGetWidth(self.view.frame), 512 } }] autorelease];
		[gradientView setLinearGradientFromColor:[baseColor colorWithAlphaComponent:1] anchor:irTop toColor:[baseColor colorWithAlphaComponent:0] anchor:irBottom];
		
		gradientView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
		
		[self.view addSubview:gradientView];
		[self.view sendSubviewToBack:gradientView];
					
	};
	
	if ([navController isViewLoaded])
		navController.onViewDidLoad(navController);
	
	return navController;

}

@end
