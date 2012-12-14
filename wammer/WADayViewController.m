//
//  WASwipeableTableViewController.m
//  wammer
//
//  Created by Shen Steven on 10/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADayViewController.h"
#import "WADefines.h"
#import "WATimelineViewController.h"
#import "WADataStore.h"
#import "NSDate+WAAdditions.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "WADataStore+FetchingConveniences.h"
#import "WACalendarPickerViewController.h"
#import "IRBarButtonItem.h"
#import "WADripdownMenuViewController.h"
#import "WAArticleDraftsViewController.h"
#import "WANavigationController.h"
#import "WACompositionViewController.h"
#import "WASlidingMenuViewController.h"

#import "WARemoteInterface.h"
#import "WAPhotoStreamViewController.h"
#import <CoreData+MagicalRecord.h>
#import "WADocumentStreamViewController.h"
#import "WADocumentDay.h"
#import "WAEventDay.h"
#import "WAPhotoDay.h"

static NSString * const WAPostsViewControllerPhone_RepresentedObjectURI = @"WAPostsViewControllerPhone_RepresentedObjectURI";

@interface WADayViewController () <WAArticleDraftsViewControllerDelegate, NSFetchedResultsControllerDelegate> {
	Class containedClass;
}

@property (nonatomic, readwrite, strong) IRPaginatedView *paginatedView;
@property (nonatomic, readwrite, strong) NSMutableDictionary *daysControllers;

@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation WADayViewController

- (id) initWithClassNamed:(Class)aClass {
	self = [self initWithNibName:nil bundle:nil];
	containedClass = aClass;
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self)
			return nil;
		
	self.daysControllers = [[NSMutableDictionary alloc] init];
	
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(handleCompositionSessionRequest:)
	 name:kWACompositionSessionRequestedNotification
	 object:nil];
			
	__weak WADayViewController *wSelf = self;

	self.navigationItem.rightBarButtonItem  = WABarButtonItem([UIImage imageNamed:@"Create"], @"", ^{
		[wSelf handleCompose:wSelf.navigationItem.rightBarButtonItem];
	});
	
	self.navigationItem.leftBarButtonItem = WABarButtonItem([UIImage imageNamed:@"menu"], @"", ^{
		[wSelf.viewDeckController toggleLeftView];
	});

	return self;

}

- (void) dealloc {

	[[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:kWACompositionSessionRequestedNotification
	 object:nil];
	
}

- (void)loadView
{
	
	[super loadView];

	CGRect rect = (CGRect) { CGPointZero, self.view.frame.size };
	[self.navigationController setToolbarHidden:YES];
	self.view.backgroundColor = [UIColor whiteColor];
	self.paginatedView = [[IRPaginatedView alloc] initWithFrame:rect];
	self.paginatedView.delegate = self;
	self.paginatedView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	
	[self.view addSubview: self.paginatedView];
	
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	self.navigationItem.titleView.alpha = 1;
	
	if ([containedClass isSubclassOfClass:[WATimelineViewController class]]) {
		self.title = NSLocalizedString(@"EVENTS_CONTROLLER_TITLE", @"Title for Events view");
	} else if ([containedClass isSubclassOfClass:[WAPhotoStreamViewController class]]) {
		self.title = NSLocalizedString(@"PHOTOS_TITLE", @"in day view");
	} else if ([containedClass isSubclassOfClass:[WADocumentStreamViewController class]]) {
		self.title = NSLocalizedString(@"DOCUMENTS_CONTROLLER_TITLE", @"Title for document view controller");
	}
	

}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[self.paginatedView reloadViews];

}

- (void)didReceiveMemoryWarning
{
	
	[super didReceiveMemoryWarning];
	
	__weak WADayViewController *wSelf = self;

	NSUInteger numOfSections = [self.fetchedResultsController.sections count];
	for (int idx = 0; idx < numOfSections; idx++ ) {
		
		if ((idx != wSelf.paginatedView.currentPage) && ((idx + 1) != wSelf.paginatedView.currentPage) && ((idx-1) != wSelf.paginatedView.currentPage)) {
			
			NSDate *theDay = nil;
			if ([containedClass isSubclassOfClass:[WATimelineViewController class]])
				theDay = [(WAEventDay*)self.fetchedResultsController.fetchedObjects[idx] day];
			else if ([containedClass isSubclassOfClass:[WAPhotoStreamViewController class]])
				theDay = [(WAPhotoDay*)self.fetchedResultsController.fetchedObjects[idx] day];
			else if ([containedClass isSubclassOfClass:[WADocumentStreamViewController class]])
				theDay = [(WADocumentDay*)self.fetchedResultsController.fetchedObjects[idx] day];

			if (!theDay)
				return;

			UIViewController *controller = [wSelf.daysControllers objectForKey:theDay];
			if (controller) {
				
				[controller removeFromParentViewController];
				[wSelf.daysControllers removeObjectForKey:theDay ];
				
			}
		}
		
	}
	
}

- (NSUInteger) supportedInterfaceOrientations {

	if (isPad())
		return UIInterfaceOrientationMaskAll;
	else
		return UIInterfaceOrientationMaskPortrait;

}

- (BOOL) shouldAutorotate {
	
	return YES;
	
}

#pragma mark - delegate methods for IRPaginatedView

-(void) viewDidLoad {
	
	self.daysControllers = [NSMutableDictionary dictionary];
	
	NSString *entityName = nil;
	
	if ([containedClass isSubclassOfClass:[WATimelineViewController class]]) {
		entityName = @"WAEventDay";
		
	} else if ([containedClass isSubclassOfClass:[WAPhotoStreamViewController class]]) {
		
		entityName = @"WAPhotoDay";
		
	} else if ([containedClass isSubclassOfClass:[WADocumentStreamViewController class]]) {
		
		entityName = @"WADocumentDay";

	}
	
	NSManagedObjectContext *context = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
	[request setEntity:entity];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"day" ascending:NO];
	[request setSortDescriptors:@[sortDescriptor]];
		
	self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];

	self.fetchedResultsController.delegate = self;

	NSError *error = nil;
		
	if(![self.fetchedResultsController performFetch:&error]) {
		NSLog(@"%@: failed to fetch files for documents", __FUNCTION__);
	}


}

- (NSUInteger)numberOfViewsInPaginatedView:(IRPaginatedView *)paginatedView {
	
	return [self.fetchedResultsController.fetchedObjects count];
	
}

- (id) controllerAtPageIndex: (NSUInteger) index {
	
	NSDate *dateForPage = nil;
	if ([containedClass isSubclassOfClass:[WATimelineViewController class]])
		dateForPage = [(WAEventDay*)self.fetchedResultsController.fetchedObjects[index] day];
	else if ([containedClass isSubclassOfClass:[WAPhotoStreamViewController class]])
		dateForPage = [(WAPhotoDay*)self.fetchedResultsController.fetchedObjects[index] day];
	else if ([containedClass isSubclassOfClass:[WADocumentStreamViewController class]])
		dateForPage = [(WADocumentDay*)self.fetchedResultsController.fetchedObjects[index] day];
	
	if (dateForPage == nil)
		return nil;
	
	id vc = self.daysControllers[dateForPage];
	
	if (vc == nil) {
		vc = [[containedClass alloc] initWithDate:dateForPage];
		if ( [vc isKindOfClass:[WAPhotoStreamViewController class]]  ) {
			((WAPhotoStreamViewController *)vc).delegate = self;
		}
		(self.daysControllers)[dateForPage] = vc;
	}
	
	return vc;
	
}


- (UIView *) viewForPaginatedView:(IRPaginatedView *)paginatedView atIndex:(NSUInteger)index {

	UIViewController *viewController = [self controllerAtPageIndex:index];
	if (!viewController)
		return nil;
	
	if (!viewController.parentViewController)
		[self addChildViewController:viewController];
	
	if (viewController)
		return viewController.view;
	
	return nil;
	
}

- (void) willRemoveView:(UIView *)view atIndex:(NSUInteger)index {

	NSDate *dateForPage = nil;
	if ([containedClass isSubclassOfClass:[WATimelineViewController class]])
		dateForPage = [(WAEventDay*)self.fetchedResultsController.fetchedObjects[index] day];
	else if ([containedClass isSubclassOfClass:[WAPhotoStreamViewController class]])
		dateForPage = [(WAPhotoDay*)self.fetchedResultsController.fetchedObjects[index] day];
	else if ([containedClass isSubclassOfClass:[WADocumentStreamViewController class]])
		dateForPage = [(WADocumentDay*)self.fetchedResultsController.fetchedObjects[index] day];

	UIViewController *controller = (self.daysControllers)[dateForPage];
	if (controller)
		[controller removeFromParentViewController];
	
}

- (void)paginatedView:(IRPaginatedView *)paginatedView didShowView:(UIView *)aView atIndex:(NSUInteger)index {
	
}

- (UIViewController *) viewControllerForSubviewAtIndex:(NSUInteger)index inPaginatedView:(IRPaginatedView *)paginatedView {

	return [self controllerAtPageIndex:index];
	
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {

	switch (type) {
		case NSFetchedResultsChangeInsert:
		case NSFetchedResultsChangeDelete:
			if ([self isViewLoaded])
				[self.paginatedView reloadViews];
			break;
			
		default:
			break;
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
	
	NSURL *contentURL = [incomingNotification userInfo][@"foundURL"];
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
		
		[compositionVC handleImageAttachmentInsertionRequestWithOptions:@{WACompositionImageInsertionUsesCamera: (id)kCFBooleanTrue, WACompositionImageInsertionAnimatePresentation: (id)kCFBooleanFalse, WACompositionImageInsertionCancellationTriggersSessionTermination: (id)kCFBooleanTrue} sender:compositionVC.view];
		
		[[UIApplication sharedApplication].keyWindow.layer addAnimation:((^ {
			
			CATransition *transition = [CATransition animation];
			transition.duration = 0.3f;
			transition.type = kCATransitionFade;
			
			return transition;
			
		})()) forKey:kCATransition];
		
	}];
	
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
- (void)jumpToRecentDay {
	
	[self.paginatedView scrollToPageAtIndex:0 animated:YES];
		
}


- (BOOL)jumpToDate:(NSDate*)date animated:(BOOL)animated{
	
	__block BOOL found = NO;
	__block NSUInteger foundIndex = 0;
		
	NSUInteger numOfSections = [self.fetchedResultsController.sections count];
	for (int idx = 0; idx < numOfSections; idx++ ) {

		NSDate *theDay = nil;
		if ([containedClass isSubclassOfClass:[WATimelineViewController class]])
			theDay = [(WAEventDay*)self.fetchedResultsController.fetchedObjects[idx] day];
		else if ([containedClass isSubclassOfClass:[WAPhotoStreamViewController class]])
			theDay = [(WAPhotoDay*)self.fetchedResultsController.fetchedObjects[idx] day];
		else if ([containedClass isSubclassOfClass:[WADocumentStreamViewController class]])
			theDay = [(WADocumentDay*)self.fetchedResultsController.fetchedObjects[idx] day];

		if (!theDay)
			return NO;
		
		if (isSameDay(theDay, date)) {
			foundIndex = idx;
			found = YES;
			break;
		}
		
	}
	
	if (found) {
		
		[self.paginatedView scrollToPageAtIndex:foundIndex animated:animated];
		return YES;
		
	}
	
	return NO;
}


@end
