//
//  WASwipeableTableViewController.m
//  wammer
//
//  Created by Shen Steven on 10/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//
#import <CoreData+MagicalRecord.h>

#import "WADayViewController.h"
#import "WADefines.h"
#import "WAAppDelegate_iOS.h"
#import "NSDate+WAAdditions.h"

#import "IRBarButtonItem.h"
#import "WAContextMenuViewController.h"
#import "WANavigationController.h"
#import "WASlidingMenuViewController.h"

#import "WATimelineViewController.h"
#import "WAPhotoStreamViewController.h"
#import "WADocumentStreamViewController.h"
#import "WAWebStreamViewController.h"

static const NSUInteger kWAAppendingBatchSize = 30;
static NSString * const WAPostsViewControllerPhone_RepresentedObjectURI = @"WAPostsViewControllerPhone_RepresentedObjectURI";

@interface WADayViewController () <NSFetchedResultsControllerDelegate, WAContextMenuDelegate> {
	Class containedClass;
	WADayViewSupportedStyle presentingStyle;
	BOOL contextMenuOpened;
}

@property (nonatomic, readonly) NSUInteger currentTotalPageSize;
@property (nonatomic, readonly) NSDate *beginningDate;

@property (nonatomic, readwrite, strong) IRPaginatedView *paginatedView;
@property (nonatomic, readwrite, strong) NSMutableDictionary *daysControllers;

@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation WADayViewController

- (id) initWithStyle:(WADayViewSupportedStyle)style {
	self = [self initWithNibName:nil bundle:nil];
	presentingStyle = style;
	switch (style) {
		case WAEventsViewStyle:
			containedClass = [WATimelineViewController class];
			break;
		case WAPhotosViewStyle:
			containedClass = [WAPhotoStreamViewController class];
			break;
		case WADocumentsViewStyle:
			containedClass = [WADocumentStreamViewController class];
			break;
		case WAWebpagesViewStyle:
			containedClass = [WAWebStreamViewController class];
			break;
		default:
			NSAssert(FALSE, @"Not a valid Day View style inited");
			break;
	}
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self)
			return nil;
		
	_currentTotalPageSize = kWAAppendingBatchSize;
	_beginningDate = [NSDate date]; // init with today
	
	self.daysControllers = [[NSMutableDictionary alloc] init];
		
	__weak WADayViewController *wSelf = self;

	self.navigationItem.leftBarButtonItem = WABarButtonItem([UIImage imageNamed:@"menu"], @"", ^{
		[wSelf.viewDeckController toggleLeftView];
	});

	return self;

}

- (void)loadView
{
	
	[super loadView];

	CGRect rect = (CGRect) { CGPointZero, self.view.frame.size };
	[self.navigationController setToolbarHidden:YES];
	self.view.backgroundColor = [UIColor whiteColor];
	self.paginatedView = [[IRPaginatedView alloc] initWithFrame:rect];
  self.paginatedView.numberOfEnsuringPages = 10;
	self.paginatedView.delegate = self;
	self.paginatedView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  self.navigationItem.titleView = [WAContextMenuViewController titleViewForContextMenu:presentingStyle
							 performSelector:@selector(contextMenuTapped)
							      withObject:self];
	[self.view addSubview: self.paginatedView];

	contextMenuOpened = NO;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	self.navigationItem.titleView.alpha = 1;

}

- (void) viewDidLoad {
	
	[super viewDidLoad];
	
	[self.paginatedView reloadViews];
}

- (void)didReceiveMemoryWarning
{
	
	[super didReceiveMemoryWarning];
	
	__weak WADayViewController *wSelf = self;

	NSUInteger numOfSections = [self.fetchedResultsController.sections count];
	for (int idx = 0; idx < numOfSections; idx++ ) {
		
		if ((idx != wSelf.paginatedView.currentPage) && ((idx + 1) != wSelf.paginatedView.currentPage) && ((idx-1) != wSelf.paginatedView.currentPage)) {
			
			NSDate *theDay = [self dayAtPageIndex:idx];
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

- (NSUInteger)numberOfViewsInPaginatedView:(IRPaginatedView *)paginatedView {
	
	return self.currentTotalPageSize;
	
}

- (id) controllerAtPageIndex: (NSUInteger) index {
	
	NSDate *dateForPage = [self dayAtPageIndex:index];
	
	if (!dateForPage)
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

- (NSDate *) dayAtPageIndex:(NSInteger)idx {
	
	NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *dateComponents = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSTimeZoneCalendarUnit) fromDate:self.beginningDate];
  dateComponents.day -= idx;
  return [calendar dateFromComponents:dateComponents];

}

- (NSUInteger) pageIndexOnDate:(NSDate*)date {
	
	NSTimeInterval diff = [self.beginningDate timeIntervalSinceDate:[date dayBegin]];
	
	NSAssert1(diff>=0, @"Should not scroll to the future: %@", date);
	
	return (NSUInteger)(diff / (3600 * 24));
	
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

	NSDate *dateForPage = [self dayAtPageIndex:index];

	UIViewController *controller = (self.daysControllers)[dateForPage];
	if (controller)
		[controller removeFromParentViewController];
	
}

- (void)paginatedView:(IRPaginatedView *)paginatedView didShowView:(UIView *)aView atIndex:(NSUInteger)index {

	if ((self.paginatedView.currentPage + 2) >= self.currentTotalPageSize) {
		
		_currentTotalPageSize += kWAAppendingBatchSize;
		[self.paginatedView reloadViews];

	}
  
  UIViewController *viewController = [self controllerAtPageIndex:index];
  if ([viewController respondsToSelector:@selector(viewControllerInitialAppeareadOnDayView)])
	[viewController performSelector:@selector(viewControllerInitialAppeareadOnDayView)];
	
}

- (UIViewController *) viewControllerForSubviewAtIndex:(NSUInteger)index inPaginatedView:(IRPaginatedView *)paginatedView {

	return [self controllerAtPageIndex:index];
	
}


#pragma mark - Context menu
- (void) contextMenuTapped {
	
	__weak WADayViewController *wSelf = self;
	
	if (contextMenuOpened) {
		[self.childViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if ([obj isKindOfClass:[WAContextMenuViewController class]]) {
				
				*stop = YES;
				WAContextMenuViewController *ddMenu = (WAContextMenuViewController*)obj;
				[ddMenu dismissContextMenu];
				
			}
		}];
		return;
	}
	
	__block WAContextMenuViewController *ddMenu = [[WAContextMenuViewController alloc] initForViewStyle:presentingStyle completion:^{

		[wSelf.navigationItem.leftBarButtonItem setEnabled:YES];
		[wSelf.navigationItem.rightBarButtonItem setEnabled:YES];
		
		contextMenuOpened = NO;
		
	}];
	
	ddMenu.delegate = self;
	
	[ddMenu presentContextMenuInViewController:self];
	[self.navigationItem.leftBarButtonItem setEnabled:NO];
	[self.navigationItem.rightBarButtonItem setEnabled:NO];
	contextMenuOpened = YES;
	
}

- (void) contextMenuItemDidSelect:(WADayViewSupportedStyle)itemStyle {
	
  NSDate *theDate = [self dayAtPageIndex:self.paginatedView.currentPage];

  WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
  [appDelegate.slidingMenu switchToViewStyle:itemStyle onDate:theDate];

}

#pragma mark - Jump to specific date
- (void)jumpToRecentDay {
	
	[self.paginatedView scrollToPageAtIndex:0 animated:YES];
		
}


- (BOOL)jumpToDate:(NSDate*)date animated:(BOOL)animated{
	
	NSUInteger page = [self pageIndexOnDate:date];
	
	if (page > self.currentTotalPageSize) {
		_currentTotalPageSize = (page + kWAAppendingBatchSize);
		[self.paginatedView reloadViews];
	}
	
	[self.paginatedView scrollToPageAtIndex:page animated:animated];
	return YES;
}

@end
