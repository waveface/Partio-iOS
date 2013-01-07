//
//  WAGalleryViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/3/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAGalleryViewController.h"
#import "IRPaginatedView.h"
#import "WADataStore.h"
#import "WAGalleryImageView.h"
#import "WAImageStreamPickerView.h"
#import "UIImage+IRAdditions.h"
#import "IRLifetimeHelper.h"
#import "Foundation+IRAdditions.h"
#import "IRAsyncOperation.h"
#import "WACompositionViewController.h"
#import "WAAppDelegate_iOS.h"
#import "WADefines.h"
#import "GAI.h"
#import "WASlidingMenuViewController.h"

NSString * const kWAGalleryViewControllerContextPreferredFileObjectURI = @"WAGalleryViewControllerContextPreferredFileObjectURI";
static NSString * kWAGalleryViewControllerKVOContext = @"WAGalleryViewControllerKVOContext";


@interface WAGalleryViewController () <IRPaginatedViewDelegate, UIGestureRecognizerDelegate, UINavigationBarDelegate, WAImageStreamPickerViewDelegate, NSFetchedResultsControllerDelegate, WAGalleryImageViewDelegate, NSCacheDelegate>

@property (nonatomic, strong) NSArray *imageFiles;
@property (nonatomic, readwrite, retain) IRPaginatedView *paginatedView;

@property (nonatomic, readwrite, retain) UINavigationBar *navigationBar;
@property (nonatomic, readwrite, retain) UIToolbar *toolbar;
@property (nonatomic, readwrite, retain) UINavigationItem *previousNavigationItem;
@property (nonatomic, readwrite, retain) WAImageStreamPickerView *streamPickerView;

@property (nonatomic, readwrite, copy) void (^onViewDidLoad)(void);
@property (nonatomic, readwrite, copy) void (^onViewDidAppear)(BOOL animated);
@property (nonatomic, readwrite, copy) void (^onViewWillDisappear)(BOOL animated);
@property (nonatomic, readwrite, copy) void (^onViewDidDisappear)(BOOL animated);

- (void) waSubviewWillLayout;

@property (nonatomic, readwrite, assign) BOOL contextControlsShown;

@property (nonatomic, readwrite, assign) BOOL requiresReloadOnFetchedResultsChange;

- (WAGalleryImageView *) configureGalleryImageView:(WAGalleryImageView *)aView withFile:(WAFile *)aFile degradeQuality:(BOOL)exclusivelyUsesThumbnail forceSync:(BOOL)forceSynchronousImageDecode;

- (void) adjustStreamPickerView;

@end


@implementation WAGalleryViewController
@dynamic view;
@synthesize navigationBar, toolbar, previousNavigationItem;
@synthesize paginatedView;
@synthesize streamPickerView;
@synthesize contextControlsShown;
@synthesize onDismiss;
@synthesize onViewDidLoad, onViewDidAppear, onViewWillDisappear, onViewDidDisappear;
@synthesize requiresReloadOnFetchedResultsChange;


+ (WAGalleryViewController *) controllerRepresentingArticleAtURI:(NSURL *)anArticleURI {

	return [self controllerRepresentingArticleAtURI:anArticleURI context:nil];

}

+ (WAGalleryViewController *) controllerRepresentingArticleAtURI:(NSURL *)anArticleURI context:(NSDictionary *)context {
	
	NSManagedObjectContext *moc = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
	WAArticle *article = (WAArticle *)[moc irManagedObjectForURI:anArticleURI];

	NSURL *preferredObjectURI = context[kWAGalleryViewControllerContextPreferredFileObjectURI];
	WAFile *preferredFile = (WAFile *)[moc irManagedObjectForURI:preferredObjectURI];
	NSArray *fileArray = [article.files array];
	NSUInteger fileIndex = [fileArray indexOfObject:preferredFile];

	WAGalleryViewController *controller = [[self alloc] initWithImageFiles:fileArray atIndex:fileIndex];

	return controller;

}

- (WAGalleryViewController *) initWithImageFiles:(NSArray *)files atIndex:(NSUInteger)index {

	self = [super init];

	if (self) {

		self.wantsFullScreenLayout = YES;
		self.imageFiles = files;

		__weak WAGalleryViewController *wSelf = self;
		self.onViewDidLoad = ^ {
			[wSelf.paginatedView layoutSubviews];
			[[wSelf streamPickerView] didSelectItemAtIndex:index];
		};
		if ([self isViewLoaded]) {
			self.onViewDidLoad();
		}

	}

	return self;

}

- (NSUInteger) supportedInterfaceOrientations {
	
	return UIInterfaceOrientationMaskAll;
	
}

- (BOOL) shouldAutorotate {
	
	return YES;
	
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	[self adjustStreamPickerView];

}

- (void) loadView {

	NSParameterAssert([self.imageFiles count]);

	__weak WAGalleryViewController *wSelf = self;

	self.view = [[IRView alloc] initWithFrame:(CGRect){ 0, 0, 512, 512 }];
	self.view.backgroundColor = [UIColor blackColor];
	self.view.onLayoutSubviews = ^ {
		[wSelf waSubviewWillLayout];
	};
	
	self.previousNavigationItem = [[UINavigationItem alloc] init];
	
	self.paginatedView = [[IRPaginatedView alloc] initWithFrame:self.view.bounds];
	self.paginatedView.horizontalSpacing = 24.0f;
	self.paginatedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.paginatedView.delegate = self;

	self.navigationBar = [[UINavigationBar alloc] initWithFrame:(CGRect){ 0.0f, 0.0f, CGRectGetWidth(self.view.bounds), 44.0f }];
	self.navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
	self.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	self.navigationBar.delegate = self;
	self.navigationBar.translucent = YES;
	self.navigationBar.tintColor = [UIColor clearColor];

	NSParameterAssert(self.previousNavigationItem);
	NSParameterAssert(self.navigationItem);
	
	[self.navigationBar pushNavigationItem:self.previousNavigationItem animated:NO];
	[self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
	
	self.toolbar = [[UIToolbar alloc] initWithFrame:(CGRect){ 0.0f, CGRectGetHeight(self.view.bounds) - 44.0f, CGRectGetWidth(self.view.bounds), 44.0f }];
	self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
	self.toolbar.barStyle = UIBarStyleBlackTranslucent;
	self.toolbar.tintColor = [UIColor clearColor];
	self.toolbar.translucent = YES;
	
	self.toolbarItems = [NSArray arrayWithObjects:
											 [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
											 [[UIBarButtonItem alloc] initWithCustomView:self.streamPickerView],
											 [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
											 nil];
	
	if (!self.navigationController)
		self.toolbar.items = self.toolbarItems;
	
	[self.view addSubview:self.paginatedView];
	[self.view addSubview:self.navigationBar];
	[self.view addSubview:self.toolbar];
	
	self.contextControlsShown = YES;
	
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBackgroundTap:)];
	tapRecognizer.delegate = self;
	[self.view addGestureRecognizer:tapRecognizer];
	
	UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBackgroundDoubleTap:)];
	doubleTapRecognizer.numberOfTapsRequired = 2;
	[tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
	[self.view addGestureRecognizer:doubleTapRecognizer];
	
	[self adjustStreamPickerView];
	
}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	if (self.onViewDidLoad)
		self.onViewDidLoad();
	
	self.paginatedView.scrollView.delaysContentTouches = NO;
	self.paginatedView.scrollView.canCancelContentTouches = NO;
	
	[self.paginatedView.scrollView.panGestureRecognizer addTarget:self action:@selector(handlePan:)];

	[[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Gallery"
																									 withAction:@"Enter gallery"
																										withLabel:nil
																										withValue:nil];

}

- (void) viewWillAppear:(BOOL)animated {
	
	if (self.navigationController) {

		UINavigationController *navC = self.navigationController;

		UIBarStyle oldNavBarStyle = navC.navigationBar.barStyle;
		BOOL oldNavBarWasTranslucent = navC.navigationBar.translucent;
		UIBarStyle oldToolBarStyle = navC.toolbar.barStyle;
		BOOL oldToolBarWasTranslucent = navC.toolbar.translucent;
		BOOL toolbarWasHidden = navC.toolbarHidden;
		UIColor *oldNavBarTintColor = navC.navigationBar.tintColor;
		UIImage *oldNavBarBackgroundImage = [navC.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
		
		navC.navigationBar.barStyle = UIBarStyleBlackTranslucent;
		navC.navigationBar.translucent = YES;
		navC.navigationBar.tintColor = [UIColor clearColor];
		[navC.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
		
		navC.toolbar.barStyle = UIBarStyleBlackTranslucent;
		navC.toolbar.translucent = YES;
		
		navC.toolbar.items = self.toolbarItems;
		
		[self.navigationBar removeFromSuperview];
		self.navigationBar = nil;
		
		[self.toolbar removeFromSuperview];
		self.toolbar = nil;
		
		[navC setToolbarHidden:NO animated:YES];
		[navC.toolbar setBackgroundColor:nil];
		[navC.toolbar setTintColor:nil];
		[navC.toolbar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
		[navC.toolbar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsLandscapePhone];

		__weak WAGalleryViewController *wSelf = self;
		
		self.onViewDidAppear = ^ (BOOL animated) {

			wSelf.onViewDidAppear = nil;

		};
		
		self.onViewWillDisappear = ^ (BOOL animated) {

			UIApplication *app = [UIApplication sharedApplication];
			[app setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:animated];
			[app setStatusBarHidden:NO withAnimation:(animated ? UIStatusBarAnimationFade : UIStatusBarAnimationNone)];

			navC.navigationBar.barStyle = oldNavBarStyle;
			navC.navigationBar.translucent = oldNavBarWasTranslucent;
			navC.navigationBar.tintColor = [UIColor blackColor];
			
			[navC setToolbarHidden:toolbarWasHidden animated:animated];

			wSelf.paginatedView.frame = [wSelf.paginatedView.superview convertRect:wSelf.view.window.bounds fromView:nil];
			
			wSelf.onViewDidDisappear = ^ (BOOL animated) {

				navC.toolbar.barStyle = oldToolBarStyle;
				navC.toolbar.translucent = oldToolBarWasTranslucent;
				navC.navigationBar.tintColor = oldNavBarTintColor;
				[navC.navigationBar setBackgroundImage:oldNavBarBackgroundImage forBarMetrics:UIBarMetricsDefault];
				
				wSelf.paginatedView.frame = wSelf.paginatedView.superview.bounds;
				
				if (wSelf.onDismiss)
					wSelf.onDismiss();

				wSelf.onViewDidDisappear = nil;
				
			};
			
			wSelf.onViewWillDisappear = nil;

		};

	} else {

		self.navigationBar.barStyle = UIBarStyleBlackTranslucent;
		self.navigationBar.translucent = YES;
		self.navigationBar.tintColor = [UIColor clearColor];
		[self.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];

	}
	
	[self adjustStreamPickerView];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
	
	[super viewWillAppear:animated];
	
	[self.paginatedView reloadViews];

}

- (void) viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];
	
	if (self.onViewDidAppear)
		self.onViewDidAppear(animated);

}

- (void) viewWillDisappear:(BOOL)animated {

	if (self.onViewWillDisappear)
		self.onViewWillDisappear(animated);
	
	[super viewWillDisappear:animated];

}

- (void) viewDidDisappear:(BOOL)animated {

	[super viewDidDisappear:animated];

	if (self.onViewDidDisappear)
		self.onViewDidDisappear(animated);

}

- (void) waSubviewWillLayout {
	
	self.navigationBar.frame = (CGRect){

		(CGPoint){
			self.navigationBar.frame.origin.x,
			MAX(20, [self.view convertRect:[[UIApplication sharedApplication] statusBarFrame] fromView:nil].size.height)
		},
		self.navigationBar.frame.size

	};

}

- (void) handlePan:(UIPanGestureRecognizer *)panGR {
	
	if (panGR.state == UIGestureRecognizerStateChanged) {

		[self setContextControlsHidden:YES animated:YES barringInteraction:NO completion:nil];

	}

}

- (NSUInteger) currentIndexForImageStreamPickerView {

	return self.paginatedView.currentPage;

}

- (void) galleryImageViewDidReceiveUserInteraction:(WAGalleryImageView *)imageView {

	[self setContextControlsHidden:YES animated:YES barringInteraction:NO completion:nil];

}

- (BOOL) navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {

	if (self.onDismiss)
		dispatch_async(dispatch_get_main_queue(), self.onDismiss);
	
	return NO;

}

- (NSUInteger) numberOfViewsInPaginatedView:(IRPaginatedView *)paginatedView {

	return [self.imageFiles count];

}

- (void)willRemoveView:(UIView *)view atIndex:(NSUInteger)index {

	id file = self.imageFiles[index];
	if ([file isKindOfClass:[WAFile class]]) {
		[file irRemoveObserverBlocksForKeyPath:@"smallestPresentableImage"];
		[file irRemoveObserverBlocksForKeyPath:@"bestPresentableImage"];
		[file cleanImageCache];
	} else if ([file isKindOfClass:[WAFilePageElement class]]) {
		[file irRemoveObserverBlocksForKeyPath:@"thumbnailImage" context:&kWAGalleryViewControllerKVOContext];
		[file cleanImageCache];
	}

}

- (void)paginatedView:(IRPaginatedView *)paginatedView didShowView:(UIView *)aView atIndex:(NSUInteger)index {

	if (self.streamPickerView.selectedItemIndex != index) {

		[self.streamPickerView setSelectedItemIndex:index];
		[self.streamPickerView setNeedsLayout];

	}

}

- (UIView *) viewForPaginatedView:(IRPaginatedView *)aPaginatedView atIndex:(NSUInteger)index {
	
	WAGalleryImageView *view = [WAGalleryImageView viewForImage:nil];
	view.frame = (CGRect){ CGPointZero, aPaginatedView.bounds.size };

	id file = self.imageFiles[index];
	if ([file isKindOfClass:[WAFile class]]) {
		return [self configureGalleryImageView:view withFile:file degradeQuality:NO forceSync:YES];
	} else if ([file isKindOfClass:[WAFilePageElement class]]) {
		[file irObserve:@"thumbnailImage" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:&kWAGalleryViewControllerKVOContext withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
			[view setImage:toValue animated:NO synchronized:YES];
			[view setNeedsLayout];
		}];
		view.delegate = self;
		[view reset];
		return view;
	}

	return nil;

}

- (UIViewController *) viewControllerForSubviewAtIndex:(NSUInteger)index inPaginatedView:(IRPaginatedView *)paginatedView {

	return nil;

}

- (WAGalleryImageView *) configureGalleryImageView:(WAGalleryImageView *)aView withFile:(WAFile *)aFile degradeQuality:(BOOL)exclusivelyUsesThumbnail forceSync:(BOOL)forceSynchronousImageDecode {

	if (exclusivelyUsesThumbnail) {

		__weak WAGalleryViewController *wSelf = self;
		[aFile irObserve:@"smallestPresentableImage" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				[aView setImage:toValue animated:NO synchronized:forceSynchronousImageDecode];
				[aView setNeedsLayout];
				
				// Show image in streamPickerView when download completed
				if (!fromValue && toValue) {
					[[wSelf streamPickerView] reloadData];
				}
				
			});
			
		}];
		
	} else {
		
		__weak WAGalleryViewController *wSelf = self;
		[aFile irObserve:@"bestPresentableImage" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				[aView setImage:toValue animated:NO synchronized:forceSynchronousImageDecode];
				[aView setNeedsLayout];
				
				// Show image in streamPickerView when download completed
				if (!fromValue && toValue) {
					[[wSelf streamPickerView] reloadData];
				}
				
			});
			
		}];
		
	}

	aView.delegate = self;
	
  [aView reset];
	
	return aView;

}

- (WAImageStreamPickerView *) streamPickerView {

	if (streamPickerView)
		return streamPickerView;
	
	self.streamPickerView = [[WAImageStreamPickerView alloc] init];
	self.streamPickerView.delegate = self;
	self.streamPickerView.style = WAClippedThumbnailsStyle;
	self.streamPickerView.exclusiveTouch = YES;
	
	[self.streamPickerView reloadData];
	
	return streamPickerView;

}

- (void) adjustStreamPickerView {

	UIToolbar *usedBar = ((self.navigationController && !self.navigationController.toolbarHidden) ? self.navigationController.toolbar : self.toolbar);
	NSParameterAssert(usedBar);

	self.streamPickerView.frame = CGRectInset(usedBar.bounds, 10, 0);

}

- (NSUInteger) numberOfItemsInImageStreamPickerView:(WAImageStreamPickerView *)picker {

	return [self.imageFiles count];

}

- (id) itemAtIndex:(NSUInteger)anIndex inImageStreamPickerView:(WAImageStreamPickerView *)picker {

  return self.imageFiles[anIndex];

}

- (UIImage *) thumbnailForItem:(id)anItem inImageStreamPickerView:(WAImageStreamPickerView *)picker {

	// FIXME: Should use KVO to refresh items in streamPickerView

	if ([anItem isKindOfClass:[WAFile class]]) {
		return [anItem extraSmallThumbnailImage];
	} else if ([anItem isKindOfClass:[WAFilePageElement class]]) {
		return [anItem extraSmallThumbnailImage];
	}
	return nil;

}

- (void) imageStreamPickerView:(WAImageStreamPickerView *)picker didSelectItemAtIndex:(NSUInteger)index {

	[self.paginatedView scrollToPageAtIndex:index animated:NO];

}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {

	if (![gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]])
		return YES;

	if (!self.contextControlsShown)
		return YES;

	if (CGRectContainsPoint(UIEdgeInsetsInsetRect(self.navigationBar.bounds, (UIEdgeInsets){ -20, -20, -20, -20 }), [touch locationInView:self.navigationBar]))
		return NO;
	
	if (CGRectContainsPoint(UIEdgeInsetsInsetRect(self.toolbar.bounds, (UIEdgeInsets){ -20, -20, -20, -20 }), [touch locationInView:self.toolbar]))
		return NO;
	
	return YES;

}

- (void) handleBackgroundDoubleTap:(UITapGestureRecognizer *)tapRecognizer {

	if (!self.paginatedView.numberOfPages)
		return;

	WAGalleryImageView *currentPage = (WAGalleryImageView *)[self.paginatedView existingPageAtIndex:self.paginatedView.currentPage];
	
	if (![currentPage isKindOfClass:[WAGalleryImageView class]])
		return;
	
	[currentPage handleDoubleTap:tapRecognizer];
	
}

- (void) handleBackgroundTap:(UITapGestureRecognizer *)tapRecognizer {

	[self setContextControlsHidden:self.contextControlsShown animated:YES completion:nil];

}

- (void) setContextControlsHidden:(BOOL)willHide animated:(BOOL)animate completion:(void(^)(void))callback {

	[self setContextControlsHidden:willHide animated:animate barringInteraction:YES completion:callback];

}

- (void) setContextControlsHidden:(BOOL)willHide animated:(BOOL)animate barringInteraction:(BOOL)barringInteraction completion:(void(^)(void))callback {

	if (contextControlsShown == !willHide)
		return;
	
	NSTimeInterval animationDuration = animate ? 0.3f : 0.0f;
	
	if (barringInteraction && (animationDuration > 0)) {

		[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, animationDuration * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		});

	}

	[[UIApplication sharedApplication] setStatusBarHidden:willHide withAnimation:(animate ? UIStatusBarAnimationFade : UIStatusBarAnimationNone)];

	[self.view setNeedsLayout];
	[self.view layoutSubviews];
	
	if (!willHide) {

		CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
		
		CGRect newOwnNavBarFrame = self.navigationBar.frame;
		newOwnNavBarFrame.origin.y = CGRectGetMaxY([self.view.window convertRect:statusBarFrame toView:self.view]);
		self.navigationBar.frame = newOwnNavBarFrame;
		
		[self.navigationController.view setNeedsLayout];
		[self.navigationController.view layoutSubviews];
		
		CGRect newNavControllerNavBarFrame = self.navigationController.navigationBar.frame;
		newNavControllerNavBarFrame.origin.y = CGRectGetMaxY([self.navigationController.view.window convertRect:statusBarFrame toView:self.navigationController.view]);
		self.navigationController.navigationBar.frame = newNavControllerNavBarFrame;

	}
	
	UIViewAnimationOptions animationOptions = UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionOverrideInheritedCurve|UIViewAnimationOptionOverrideInheritedDuration;
	
	if (!barringInteraction)
		animationOptions |= UIViewAnimationOptionAllowUserInteraction;
	
	[UIView animateWithDuration:animationDuration delay:0.0f options:animationOptions animations:^(void) {

		self.navigationBar.alpha = (willHide ? 0.0f : 1.0f);
		self.toolbar.alpha = (willHide ? 0.0f : 1.0f);
		
		CGRect oldNavControllerNavBarFrame = self.navigationController.navigationBar.frame;
		
		self.navigationController.navigationBar.alpha = (willHide ? 0.0f : 1.0f);
		self.navigationController.toolbar.alpha = (willHide ? 0.0f : 1.0f);
		
		self.navigationController.navigationBar.frame = oldNavControllerNavBarFrame;

		[(WAAppDelegate_iOS *)AppDelegate() slidingMenu].statusBar.alpha = willHide ? 0.0f : 1.0f;
		
	} completion: ^ (BOOL didFinish){

		if (callback)
			callback();

	}];
	
	self.contextControlsShown = willHide ? NO : YES;

}

- (UIImage *) currentImage {

	return ((WAGalleryImageView *)[self.paginatedView existingPageAtIndex:self.paginatedView.currentPage]).image;

}

- (void) didReceiveMemoryWarning {

	[super didReceiveMemoryWarning];

}

- (void) dealloc {
	
	[self.paginatedView irRemoveObserverBlocksForKeyPath:@"currentPage"];
	for (id file in self.imageFiles) {
		if ([file isKindOfClass:[WAFile class]]) {
			[file irRemoveObserverBlocksForKeyPath:@"bestPresentableImage"];
			[file irRemoveObserverBlocksForKeyPath:@"smallestPresentableImage"];
		} else if ([file isKindOfClass:[WAFilePageElement class]]) {
			[file irRemoveObserverBlocksForKeyPath:@"thumbnailImage" context:&kWAGalleryViewControllerKVOContext];
		}
	}
	
	[self.streamPickerView irRemoveObserverBlocksForKeyPath:@"selectedItemIndex"];
	
	self.paginatedView = nil;
	self.navigationBar = nil;
	self.toolbar = nil;
	self.previousNavigationItem = nil;
	self.streamPickerView = nil;
		
	[self.paginatedView irRemoveObserverBlocksForKeyPath:@"currentPage"];
	
	if ([self isViewLoaded])
		self.view.onLayoutSubviews = nil;

	[self.paginatedView removeFromSuperview];	//	Also triggers page deallocation

}

@end
