//
//  WASwipeableTableViewController.m
//  wammer
//
//  Created by Shen Steven on 10/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADayViewController.h"
#import "WADefines.h"
#import "WATimelineViewControllerPhone.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "WADataStore+FetchingConveniences.h"
#import "IRTableView.h"
#import "WADatePickerViewController.h"
#import "WADripdownMenuViewController.h"
#import "WAArticleDraftsViewController.h"
#import "WANavigationController.h"
#import "WACompositionViewController.h"
#import "WASlidingMenuViewController.h"

#import "WARemoteInterface.h"

static NSString * const WAPostsViewControllerPhone_RepresentedObjectURI = @"WAPostsViewControllerPhone_RepresentedObjectURI";

@interface WADayViewController () <WAArticleDraftsViewControllerDelegate>

@property (nonatomic, readwrite, strong) IRPaginatedView *paginatedView;
@property (nonatomic, readwrite, strong) NSMutableDictionary *daysControllers;
@property (nonatomic, readwrite, strong) NSMutableArray *days;

@end

@implementation WADayViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self)
			return nil;
		
	self.days = [NSMutableArray array];
	self.daysControllers = [[NSMutableDictionary alloc] init];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCompositionSessionRequest:) name:kWACompositionSessionRequestedNotification object:nil];
	
	[[WARemoteInterface sharedInterface] addObserver:self forKeyPath:@"isPostponingDataRetrievalTimerFiring" options:NSKeyValueObservingOptionPrior|NSKeyValueObservingOptionNew context:nil];
	
	self.title = NSLocalizedString(@"APP_TITLE", @"Title for application");
//	self.navigationItem.titleView = WATitleViewForDripdownMenu(self, @selector(dripdownMenuTapped));
	self.navigationItem.titleView = WAStandardTitleView();
	
	CGRect rect = (CGRect){ CGPointZero, (CGSize){ 1, 1 } };
	UIGraphicsBeginImageContext(rect.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
	CGContextFillRect(context, rect);
	UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	UIImage *cameraPressed = [UIImage imageNamed:@"CameraPressed"];
	UIButton *cameraButton = [[UIButton alloc] initWithFrame:(CGRect){ CGPointZero, cameraPressed.size }];
	[cameraButton setBackgroundImage:cameraPressed forState:UIControlStateHighlighted];
	[cameraButton addTarget:self action:@selector(handleCameraCapture:) forControlEvents:UIControlEventTouchUpInside];
	[cameraButton setShowsTouchWhenHighlighted:YES];
	
	UIImage *notePressed = [UIImage imageNamed:@"NotePressed"];
	UIButton *noteButton = [[UIButton alloc] initWithFrame:(CGRect){ CGPointZero, notePressed.size }];
	[noteButton setBackgroundImage:notePressed forState:UIControlStateHighlighted];
	[noteButton addTarget:self action:@selector(handleCompose:) forControlEvents:UIControlEventTouchUpInside];
	[noteButton setShowsTouchWhenHighlighted:YES];
	
	UIBarButtonItem *alphaSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
	alphaSpacer.width = 14.0;
	
	UIBarButtonItem *omegaSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
	omegaSpacer.width = 34.0;
	
	UIBarButtonItem *zeroSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
	zeroSpacer.width = -10;
	
	UIBarButtonItem *leftUIButton = [[UIBarButtonItem alloc] initWithImage:transparentImage style:UIBarButtonItemStylePlain target:self action:@selector(handleSwipeRight:)];
	[leftUIButton setAccessibilityLabel:NSLocalizedString(@"ACCESS_NEXT_DAY", @"Accessibility label for next day timeline")];

	UIBarButtonItem *composeUIButton = [[UIBarButtonItem alloc] initWithCustomView:noteButton];
	[composeUIButton setAccessibilityLabel:NSLocalizedString(@"ACCESS_COMPOSE", @"Accessibility label for composer in iPhone timeline")];
	
	UIBarButtonItem *cameraUIButton = [[UIBarButtonItem alloc] initWithCustomView:cameraButton];
	[cameraButton setAccessibilityLabel:NSLocalizedString(@"ACCESS_CAMERA", @"Accessibility label for camera in iPhone timeline")];
	
	UIBarButtonItem *rightUIButton = [[UIBarButtonItem alloc] initWithImage:transparentImage style:UIBarButtonItemStylePlain target:self action:@selector(handleSwipeLeft:)];
	[leftUIButton setAccessibilityLabel:NSLocalizedString(@"ACCESS_PREVIOUS_DAY", @"Accessibility label for previous day timeline")];
	
	
	self.toolbarItems = [NSArray arrayWithObjects:
											 
											 alphaSpacer,
											 
											 //		datePickUIButton,
											 leftUIButton,
											 
											 omegaSpacer,
											 
											 composeUIButton,
											 
											 zeroSpacer,
											 
											 cameraUIButton,
											 
											 omegaSpacer,
											 
											 //userInfoUIButton,
											 rightUIButton,
											 
											 alphaSpacer,
											 
											 nil];
	
	UIImage *createImage = [UIImage imageNamed:@"Create"];
	UIButton *createButton = [UIButton buttonWithType:UIButtonTypeCustom];
	createButton.frame = (CGRect) {CGPointZero, createImage.size};
	[createButton setBackgroundImage:createImage forState:UIControlStateNormal];
//	[calButton setBackgroundImage:[UIImage imageNamed:@"CalHL"] forState:UIControlStateHighlighted];
	[createButton setShowsTouchWhenHighlighted:YES];
	[createButton addTarget:self action:@selector(handleCompose:) forControlEvents:UIControlEventTouchUpInside];
	
	self.navigationItem.rightBarButtonItem  = [[UIBarButtonItem alloc] initWithCustomView:createButton];
	
	UIImage *menuImage = [UIImage imageNamed:@"menu"];
	UIButton *slidingMenuButton = [UIButton buttonWithType:UIButtonTypeCustom];
	slidingMenuButton.frame = (CGRect) {CGPointZero, menuImage.size};
	[slidingMenuButton setBackgroundImage:menuImage forState:UIControlStateNormal];
//	[slidingMenuButton setBackgroundImage:[UIImage imageNamed:@"menuHL"] forState:UIControlStateHighlighted];
	[slidingMenuButton setShowsTouchWhenHighlighted:YES];
	[slidingMenuButton addTarget:self.viewDeckController action:@selector(toggleLeftView) forControlEvents:UIControlEventTouchUpInside];
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:slidingMenuButton];

	return self;
}

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self name:kWACompositionSessionRequestedNotification object:nil];
  [[WARemoteInterface sharedInterface] removeObserver:self forKeyPath:@"isPostponingDataRetrievalTimerFiring"];
	
}


- (void)loadView
{
	
	[super loadView];

	CGRect origFrame = self.view.frame;
	origFrame.origin = CGPointZero;
	
	self.view.backgroundColor = [UIColor whiteColor];
	self.paginatedView = [[IRPaginatedView alloc] initWithFrame:origFrame];
	self.paginatedView.delegate = self;
	
	[self.view addSubview: self.paginatedView];

	[self.paginatedView reloadViews];
	
}

- (void) viewWillAppear:(BOOL)animated {

	self.navigationItem.titleView.alpha = 1;
	
	[self.navigationController.toolbar setHidden:YES];
//	[self.navigationController.toolbar setTintColor:[UIColor colorWithWhite:128.0/255.0 alpha:1]];
//	[self.navigationController.toolbar setBackgroundImage:[UIImage imageNamed:@"ToolbarWithButtons"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

}

- (void) viewDidAppear:(BOOL)animated {

	[self.navigationController setToolbarHidden:YES animated:animated];

}

- (void) viewWillDisappear:(BOOL)animated {

	UIToolbar *toolbar = self.navigationController.toolbar;
	
	[toolbar setBackgroundImage:[UIImage imageNamed:@"Toolbar"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
	
	[toolbar setNeedsLayout];
	
	[toolbar.layer addAnimation:((^ {
		
		CATransition *transition = [CATransition animation];
		transition.duration = animated ? 0.5 : 0;
		transition.type = kCATransitionFade;
		
		return transition;
		
	})()) forKey:kCATransition];

}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


#pragma mark - delegate methods for IRPaginatedView
- (NSUInteger)numberOfViewsInPaginatedView:(IRPaginatedView *)paginatedView {
		
	NSManagedObjectContext *moc = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"WAArticle" inManagedObjectContext:moc];
	[fetchRequest setEntity:entity];
	[fetchRequest setResultType:NSDictionaryResultType];
 	
	NSExpression *keyToFetch = [NSExpression expressionForKeyPath:@"creationDate"];
	NSExpressionDescription *description = [[NSExpressionDescription alloc] init];
	[description setName:@"fetchedCreationDate"];
	[description setExpression:keyToFetch];
	[description setExpressionResultType:NSDateAttributeType];
	[fetchRequest setPropertiesToFetch:[NSArray arrayWithObject:description]];

	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
																	[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO],
																	nil];
	
	BOOL (^theSameDay) (NSDate *, NSDate *) = ^ (NSDate *d1, NSDate *d2) {
		
    NSCalendar* calendar = [NSCalendar currentCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:d1];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:d2];
    if ( [comp1 day] == [comp2 day] &&
				[comp1 month] == [comp2 month] &&
				[comp1 year]  == [comp2 year])
      return YES;
    return NO;
		
  };
	
	__block NSDate *currentDate = nil;

	NSError *error = nil;
	NSArray *objects = [moc executeFetchRequest:fetchRequest error:&error];
	
	if (objects == nil) {
		
		return 0;
		
	} else {
		
		[objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			
			NSDate *theDate = (NSDate*)obj[@"fetchedCreationDate"];
			
			if (!currentDate || !theSameDay(currentDate, theDate)) {
				[self.days addObject:theDate];
				currentDate = theDate;
			}
			
		}];
		
		return [self.days count];
	}
}

- (WATimelineViewControllerPhone *) timelineControllerAtPageIndex:(NSUInteger)index {
	
	NSDate *dateForPage = [self.days objectAtIndex:index];
	
	if (dateForPage) {
		
		WATimelineViewControllerPhone *vc = self.daysControllers[dateForPage]; 

		if (vc) {
			
			return vc;
			
		} else {

			WATimelineViewControllerPhone *newVC = [[WATimelineViewControllerPhone alloc] initWithDate:dateForPage];
			[self addChildViewController:newVC];
			[self.daysControllers setObject:newVC forKey:dateForPage];
			return newVC;
			
		}
		
	}
	
	return nil;
	
}

- (UIView *) viewForPaginatedView:(IRPaginatedView *)paginatedView atIndex:(NSUInteger)index {

	WATimelineViewControllerPhone *vc = [self timelineControllerAtPageIndex:index];
	
	if (vc)
		return vc.view;
	
	return nil;
	
}

- (void) willRemoveView:(UIView *)view atIndex:(NSUInteger)index {
	
}

- (void)paginatedView:(IRPaginatedView *)paginatedView didShowView:(UIView *)aView atIndex:(NSUInteger)index {
	
}

- (UIViewController *) viewControllerForSubviewAtIndex:(NSUInteger)index inPaginatedView:(IRPaginatedView *)paginatedView {

	return [self timelineControllerAtPageIndex:index];
	
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([self isViewLoaded])
		if (object == [WARemoteInterface sharedInterface])
			if ([[change objectForKey:NSKeyValueChangeNewKey] isEqual:(id)kCFBooleanFalse]) {
				
				[self.paginatedView reloadViews];
				
			}
	
}

#pragma mark - delegate methods for WAArticleDraftsViewControllerDelegate
- (BOOL) articleDraftsViewController:(WAArticleDraftsViewController *)aController shouldEnableArticle:(NSURL *)anObjectURIOrNil {
	
	return ![[WADataStore defaultStore] isUpdatingArticle:anObjectURIOrNil];
	
}

- (void) articleDraftsViewController:(WAArticleDraftsViewController *)aController didSelectArticle:(NSURL *)anObjectURIOrNil {
	
  [aController dismissViewControllerAnimated:YES completion:^{
		
		[self beginCompositionSessionWithURL:anObjectURIOrNil animated:YES onCompositionViewDidAppear:nil];
		
	}];
	
}

- (void) beginCompositionSessionWithURL:(NSURL *)anURL animated:(BOOL)animate onCompositionViewDidAppear:(void (^)(WACompositionViewController *))callback {
	
	__block WACompositionViewController *compositionVC = [WACompositionViewController defaultAutoSubmittingCompositionViewControllerForArticle:anURL completion:^(NSURL *anURI) {
		
		if (![compositionVC.article hasMeaningfulContent] && [compositionVC shouldDismissSelfOnCameraCancellation]) {
			
			__block void (^dismissModal)(UIViewController *) = [^ (UIViewController *aVC) {
				
				if (aVC.presentedViewController) {
					dismissModal(aVC.presentedViewController);
					return;
				}
				
				[aVC dismissViewControllerAnimated:NO completion:nil];
				
			} copy];
			
			UIWindow *usedWindow = [[UIApplication sharedApplication] keyWindow];
			
			if ([compositionVC isViewLoaded] && compositionVC.view.window)
				usedWindow = compositionVC.view.window;
			
			NSCParameterAssert(usedWindow);
			
			[CATransaction begin];
			
			dismissModal(compositionVC);
			dismissModal = nil;
			
			[compositionVC dismissViewControllerAnimated:NO completion:nil];
			
			CATransition *fadeTransition = [CATransition animation];
			fadeTransition.duration = 0.3f;
			fadeTransition.type = kCATransitionFade;
			fadeTransition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
			fadeTransition.removedOnCompletion = YES;
			fadeTransition.fillMode = kCAFillModeForwards;
			
			[usedWindow.layer addAnimation:fadeTransition forKey:kCATransition];
			
			[CATransaction commit];
			
		} else {
			
			[compositionVC dismissViewControllerAnimated:YES completion:nil];
			
			if (!anURL && [compositionVC.article hasMeaningfulContent]) {
//				[self setScrollToTopmostPost:YES];
			}
			
		}
		
		compositionVC = nil;
		
	}];
	
	[self presentViewController:[compositionVC wrappingNavigationController] animated:animate completion:^{
		
		if (callback)
			callback(compositionVC);
		
	}];
	
}

- (void) handleCompositionSessionRequest:(NSNotification *)incomingNotification {
	
	if (![self isViewLoaded])
		return;
	
	NSURL *contentURL = [[incomingNotification userInfo] objectForKey:@"foundURL"];
	[self beginCompositionSessionWithURL:contentURL animated:YES onCompositionViewDidAppear:nil];
	
}


- (void) handleCompose:(UIBarButtonItem *)sender {
	
	if ([[WADataStore defaultStore] hasDraftArticles]) {
		
		WAArticleDraftsViewController *draftsVC = [[WAArticleDraftsViewController alloc] init];
		draftsVC.delegate = self;
		
		WANavigationController *navC = [[WANavigationController alloc] initWithRootViewController:draftsVC];
		
		__weak WADayViewController *wSelf = self;
		
		draftsVC.navigationItem.leftBarButtonItem = [IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemCancel wiredAction:^(IRBarButtonItem *senderItem) {
			
			[wSelf dismissViewControllerAnimated:YES completion:nil];
			
		}];
		
		[self presentViewController:navC animated:YES completion:nil];
		
	} else {
		
		[self beginCompositionSessionWithURL:nil animated:YES onCompositionViewDidAppear:nil];
		
	}
  
}

- (void) handleCameraCapture:(UIBarButtonItem *)sender  {
	
	[self beginCompositionSessionWithURL:nil animated:NO onCompositionViewDidAppear:^(WACompositionViewController *compositionVC) {
		
		[compositionVC handleImageAttachmentInsertionRequestWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:
																																		 
																																		 (id)kCFBooleanTrue, WACompositionImageInsertionUsesCamera,
																																		 (id)kCFBooleanFalse, WACompositionImageInsertionAnimatePresentation,
																																		 (id)kCFBooleanTrue, WACompositionImageInsertionCancellationTriggersSessionTermination,
																																		 
																																		 nil] sender:compositionVC.view];
		
		[[UIApplication sharedApplication].keyWindow.layer addAnimation:((^ {
			
			CATransition *transition = [CATransition animation];
			transition.duration = 0.3f;
			transition.type = kCATransitionFade;
			
			return transition;
			
		})()) forKey:kCATransition];
		
	}];
	
}


#pragma mark -Date picker

- (void) jumpToTimelineOnDate:(NSDate*)date {
	
	__block BOOL found = NO;
	__block NSUInteger foundIdx = 0;
	
	[self.days enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		
		NSDate *articleDate = (NSDate*)obj;
		NSComparisonResult result = [date compare:articleDate];
		if (result == NSOrderedSame || result == NSOrderedDescending) {
			foundIdx = idx;
			found = YES;
			*stop = YES;
		}
		
	}];
	
	if (found) {
		
		[self.paginatedView scrollToPageAtIndex:foundIdx animated:YES];
		
	}
	
}

- (void) handleDateSelect:(UIBarButtonItem *)sender {
	
	NSManagedObjectContext *moc = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
	__weak WADayViewController *wSelf = self;
	
	__block WADatePickerViewController *dpVC = [WADatePickerViewController controllerWithCompletion:^(NSDate *date) {
		
		if (date) {
			
			[wSelf jumpToTimelineOnDate:date];
			
		}
		
		[dpVC willMoveToParentViewController:nil];
		[dpVC removeFromParentViewController];
		[dpVC.view removeFromSuperview];
		[dpVC didMoveToParentViewController:nil];
		
		dpVC = nil;
		
	}];
	
	NSFetchRequest *newestFr = [[WADataStore defaultStore] newFetchRequestForNewestArticle];
	NSFetchRequest *oldestFr = [[WADataStore defaultStore] newFetchRequestForOldestArticle];
	
	WAArticle *newestArticle = (WAArticle*)[[moc executeFetchRequest:newestFr error:nil] lastObject];
	WAArticle *oldestArticle = (WAArticle*)[[moc executeFetchRequest:oldestFr error:nil] lastObject];
	
	if (oldestArticle == nil){ // empty timeline
		return;
	}
	
	NSDate *minDate = oldestArticle.modificationDate ? oldestArticle.modificationDate : oldestArticle.creationDate;
	
	NSDate *maxDate = newestArticle.modificationDate ? newestArticle.modificationDate : newestArticle.creationDate;
	
	NSCParameterAssert(minDate && maxDate);
	dpVC.minDate = minDate;
	dpVC.maxDate = maxDate;
	
	UIViewController *hostingVC = self.navigationController;
	if (!hostingVC)
		hostingVC = self;
	
	[hostingVC addChildViewController:dpVC];
	
	dpVC.view.frame = hostingVC.view.bounds;
	[hostingVC.view addSubview:dpVC.view];
	[dpVC didMoveToParentViewController:hostingVC];
	
}



#pragma mark - Dripdown menu
BOOL dripdownMenuOpened = NO;
- (void) dripdownMenuTapped {
	
	__weak WADayViewController *wSelf = self;
	
	void (^dismissDDMenu)(WADripdownMenuViewController *menu) = ^(WADripdownMenuViewController *menu) {
		
		[menu willMoveToParentViewController:nil];
		[menu removeFromParentViewController];
		[menu.view removeFromSuperview];
		[menu didMoveToParentViewController:nil];
		
		[wSelf.navigationController setToolbarHidden:NO animated:NO];
		[wSelf.navigationItem.leftBarButtonItem setEnabled:YES];
		[wSelf.navigationItem.rightBarButtonItem setEnabled:YES];
		
		dripdownMenuOpened = NO;
		
	};
	
	if (dripdownMenuOpened) {
		[self.childViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if ([obj isKindOfClass:[WADripdownMenuViewController class]]) {
				
				*stop = YES;
				WADripdownMenuViewController *ddMenu = (WADripdownMenuViewController*)obj;
				dismissDDMenu(ddMenu);
				
			}
		}];
		return;
	}
	
	[self.navigationController setToolbarHidden:YES animated:YES];
	__block WADripdownMenuViewController *ddMenu = [[WADripdownMenuViewController alloc] initWithCompletion:^{
		
		dismissDDMenu(ddMenu);
		ddMenu = nil;
		
	}];
	
	[self addChildViewController:ddMenu];
	[self.view addSubview:ddMenu.view];
	[ddMenu didMoveToParentViewController:self];
	[self.navigationItem.leftBarButtonItem setEnabled:NO];
	[self.navigationItem.rightBarButtonItem setEnabled:NO];
	dripdownMenuOpened = YES;
	
}

#pragma mark - Jump to specific date
- (void)jumpToToday {
	
	[self.paginatedView scrollToPageAtIndex:0 animated:YES];
		
}


- (void) handleSwipeRight:(id) sender {
	
	if (self.paginatedView.currentPage > 0)
		[self.paginatedView scrollToPageAtIndex:self.paginatedView.currentPage-1 animated:YES];
}

- (void) handleSwipeLeft:(id) sender {
	
	if (self.paginatedView.currentPage < [self.days count])
		[self.paginatedView scrollToPageAtIndex:self.paginatedView.currentPage+1 animated:YES];
	
}


@end
