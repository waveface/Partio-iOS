//
//  WAArticlesViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WATimelineViewControllerPhone.h"

#import <objc/runtime.h>

#import <TargetConditionals.h>

#import "UIKit+IRAdditions.h"
#import "NSDate+WAAdditions.h"

#import "WADefines.h"
#import "WAAppDelegate.h"
#import "WARemoteInterface.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "WAGalleryViewController.h"

#import "WAArticleDraftsViewController.h"
#import "WACompositionViewController.h"
#import "WACompositionViewController+CustomUI.h"

#import "WAArticleViewController.h"

#import "IASKAppSettingsViewController.h"

#import "WANavigationController.h"

#import "WAArticleCommentsViewCell.h"
#import "WAPostViewCellPhone.h"
#import "WAPulldownRefreshView.h"
#import "WADayHeaderView.h"

#import "WARepresentedFilePickerViewController.h"
#import "WARepresentedFilePickerViewController+CustomUI.h"

#import "WAFilterPickerViewController.h"

#import "WATimelineViewControllerPhone+RowHeightCaching.h"

#import "UIViewController+IRDelayedUpdateAdditions.h"


@interface WATimelineViewControllerPhone () <NSFetchedResultsControllerDelegate, UIActionSheetDelegate, IASKSettingsDelegate>

- (WAPulldownRefreshView *) defaultPulldownRefreshView;

@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) IRActionSheetController *settingsActionSheetController;
@property (nonatomic, readwrite) BOOL scrollToTopmostPost;
@property (nonatomic, readwrite, retain) NSDate *currentDisplayedDate;

- (void) refreshData;

- (void) handleFilter:(UIBarButtonItem *)sender;

@end


@implementation WATimelineViewControllerPhone
@synthesize delegate;
@synthesize fetchedResultsController;
@synthesize managedObjectContext;
@synthesize settingsActionSheetController;
@synthesize scrollToTopmostPost;

- (void) dealloc {
	
  [[WARemoteInterface sharedInterface] removeObserver:self forKeyPath:@"isPostponingDataRetrievalTimerFiring"];
  
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self)
		return nil;
	
		
	[[WARemoteInterface sharedInterface] addObserver:self forKeyPath:@"isPostponingDataRetrievalTimerFiring" options:NSKeyValueObservingOptionPrior|NSKeyValueObservingOptionNew context:nil];
  
	[self setScrollToTopmostPost:NO];

	return self;
  
}

- (id) initWithDate:(NSDate*)date {
	
	self.currentDisplayedDate = [date copy];
	[self fetchedResultsController];

	return [self initWithNibName:nil bundle:nil];
	
}

- (void) irConfigure {

	[super irConfigure];
	
	self.persistsContentInset = NO;

	self.persistsStateWhenViewWillDisappear = NO;
	self.restoresStateWhenViewWillAppear = NO;
	
}



- (NSString *) persistenceIdentifier {

	return NSStringFromClass([self class]);

}





NSString * const kWAPostsViewControllerLastVisibleObjectURIs = @"WAPostsViewControllerLastVisiblePostURIs";
NSString * const kWAPostsViewControllerLastVisibleRects = @"WAPostsViewControllerLastVisibleRects";

- (NSMutableDictionary *) persistenceRepresentation {

	NSMutableDictionary *answer = [super persistenceRepresentation];
	
	if ([self isViewLoaded]) {
	
		NSArray *currentIndexPaths = [self.tableView indexPathsForVisibleRows];
		
		if (currentIndexPaths) {
		
			[answer setObject:[currentIndexPaths irMap: ^ (NSIndexPath *anIndexPath, NSUInteger index, BOOL *stop) {
				
				NSManagedObject *rowObject = [self.fetchedResultsController objectAtIndexPath:anIndexPath];
				return [[[rowObject objectID] URIRepresentation] absoluteString];
				
			}] forKey:kWAPostsViewControllerLastVisibleObjectURIs];
			
			[answer setObject:[currentIndexPaths irMap: ^ (NSIndexPath *anIndexPath, NSUInteger index, BOOL *stop) {
			
				return NSStringFromCGRect([self.tableView rectForRowAtIndexPath:anIndexPath]);
				
			}] forKey:kWAPostsViewControllerLastVisibleRects];
		
		}
	
	}
	
	return answer;

}

- (void) restoreFromPersistenceRepresentation:(NSDictionary *)inPersistenceRepresentation {

	[super restoreFromPersistenceRepresentation:inPersistenceRepresentation];
	
	if ([self isViewLoaded]) {
	
		NSArray *oldVisibleObjectURIs = [[inPersistenceRepresentation objectForKey:kWAPostsViewControllerLastVisibleObjectURIs] irMap: ^ (NSString *aString, NSUInteger index, BOOL *stop) {
			return [NSURL URLWithString:aString];
		}];
		NSArray *oldVisibleRects = [inPersistenceRepresentation objectForKey:kWAPostsViewControllerLastVisibleRects];
		
		if (oldVisibleObjectURIs && oldVisibleRects)
		if ([oldVisibleObjectURIs count] == [oldVisibleRects count]) {
		
			NSArray *newVisibleRects = [oldVisibleObjectURIs irMap: ^ (NSURL *anObjectURI, NSUInteger index, BOOL *stop) {
				NSIndexPath *newIndexPath = [self.fetchedResultsController indexPathForObject:[self.managedObjectContext irManagedObjectForURI:anObjectURI]];
				if (newIndexPath) {
					return (id)NSStringFromCGRect([self.tableView rectForRowAtIndexPath:newIndexPath]);
				} else {
					return (id)[NSNull null];
				}
			}];
			
			NSIndexSet *stillListedObjectIndexes = [oldVisibleObjectURIs indexesOfObjectsPassingTest: ^ (NSURL *anURI, NSUInteger idx, BOOL *stop) {
				return (BOOL)!![[newVisibleRects objectAtIndex:idx] isKindOfClass:[NSString class]];
			}];
			
			if ([stillListedObjectIndexes count]) {
				
				NSUInteger index = [stillListedObjectIndexes firstIndex];
				CGRect oldRect = CGRectFromString([oldVisibleRects objectAtIndex:index]);
				CGRect newRect = CGRectFromString([newVisibleRects objectAtIndex:index]);
				
				CGFloat deltaY = CGRectGetMinY(newRect) - CGRectGetMinY(oldRect);
				
				CGPoint oldContentOffset = self.tableView.contentOffset;
				CGPoint newContentOffset = oldContentOffset;
				newContentOffset.y += deltaY;
				
				if (deltaY != 0)
					[self.tableView setContentOffset:newContentOffset animated:NO];
				
			}
		
		}
	
	}

}



- (void) settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender {

	//	Do nothing

}

- (void) settingsViewController:(IASKAppSettingsViewController *)sender buttonTappedForKey:(NSString *)key {

	[[NSNotificationCenter defaultCenter] postNotificationName:kWASettingsDidRequestActionNotification object:sender userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
	
		key, @"key",
	
	nil]];

}

- (IRActionSheetController *) settingsActionSheetController {

	if (settingsActionSheetController)
		return settingsActionSheetController;
	
	__weak WATimelineViewControllerPhone *wSelf = self;
	
	IRAction *cancelAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_CANCEL", nil) block:nil];
	IRAction *signOutAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", nil) block:^{
	
		NSString *alertTitle = NSLocalizedString(@"ACTION_SIGN_OUT", nil);
		NSString *alertText = NSLocalizedString(@"SIGN_OUT_CONFIRMATION", nil);
		
		[[IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:
			
			[IRAction actionWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", nil) block: ^ {
				
				[wSelf.delegate applicationRootViewControllerDidRequestReauthentication:nil];
				
			}],
			
		nil]] show];
		
	}];
	
	settingsActionSheetController = [IRActionSheetController actionSheetControllerWithTitle:nil cancelAction:cancelAction destructiveAction:signOutAction otherActions:nil];

	return settingsActionSheetController;

}

#pragma mark - MOC and NSFetchResultsController
- (NSManagedObjectContext *) managedObjectContext {

	if (managedObjectContext)
		return managedObjectContext;
	
	managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];

	return managedObjectContext;

}

- (NSFetchedResultsController *) fetchedResultsController {

	if (fetchedResultsController)
		return fetchedResultsController;
	
	if (!self.currentDisplayedDate)
		self.currentDisplayedDate = [NSDate date];

	NSFetchRequest *fr = [[WADataStore defaultStore] newFetchRequestForArticlesOnDate:self.currentDisplayedDate];

	NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"yyyy-MM-dd" options:0 locale:[NSLocale currentLocale] ];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:formatString];
	
	NSString *cacheName = [NSString stringWithFormat:@"fetchedTableCache-%@", [formatter stringFromDate:self.currentDisplayedDate]];
	fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:cacheName];
	
	fetchedResultsController.delegate = self;
  
  NSError *fetchingError;
	if (![fetchedResultsController performFetch:&fetchingError])
		NSLog(@"error fetching: %@", fetchingError);
	
	if ([self isViewLoaded])
		[self.tableView reloadData];
	
	return fetchedResultsController;
	
}

#pragma mark -


- (void) debugCreateArticle:(NSTimer *)timer {

	WADataStore *ds = [WADataStore defaultStore];
	NSManagedObjectContext *ctx = [ds disposableMOC];
	
	[WAArticle insertOrUpdateObjectsUsingContext:ctx withRemoteResponse:[NSArray arrayWithObjects:
	
		[NSDictionary dictionaryWithObjectsAndKeys:
		
			IRDataStoreNonce(), @"content",
			[ds ISO8601StringFromDate:[NSDate date]], @"timestamp",
		
		nil],
	
	nil] usingMapping:nil options:0];
	
	[ctx save:nil];

}

#pragma mark - UIViewController lifecycle
- (WAPulldownRefreshView *) defaultPulldownRefreshView {
	
	return [WAPulldownRefreshView viewFromNib];
	
}


- (void) viewDidLoad {

	[super viewDidLoad];
	
	__weak WATimelineViewControllerPhone *wSelf = self;
	
	IRTableView* (^setupTableView)(IRTableView *) = ^(IRTableView *tbView) {
				
		tbView.separatorStyle = UITableViewCellSeparatorStyleNone;
		
		WAPulldownRefreshView *pulldownHeader = [self defaultPulldownRefreshView];
		
		tbView.pullDownHeaderView = pulldownHeader;
		tbView.onPullDownMove = ^ (CGFloat progress) {
			[pulldownHeader setProgress:progress animated:YES];
		};
		tbView.onPullDownEnd = ^ (BOOL didFinish) {
			if (didFinish) {
				pulldownHeader.progress = 0;
				[pulldownHeader setBusy:YES animated:YES];
				[[WARemoteInterface sharedInterface] performAutomaticRemoteUpdatesNow];
			}
		};
		tbView.onPullDownReset = ^ {
			[pulldownHeader setBusy:NO animated:YES];
		};
		
		tbView.separatorColor = [UIColor colorWithRed:232.0/255.0 green:232/255.0 blue:226/255.0 alpha:1.0];
		tbView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
		/*
		tbView.layer.masksToBounds = NO;
		tbView.layer.shadowRadius = 10;
		tbView.layer.shadowOpacity = 0.5;
		tbView.layer.shadowColor = [[UIColor blackColor] CGColor];
		tbView.layer.shadowOffset = CGSizeZero;
		tbView.layer.shadowPath = [[UIBezierPath bezierPathWithRect:tbView.bounds] CGPath];
		*/
		WADayHeaderView *headerView = [WADayHeaderView viewFromNib];
		headerView.dayLabel.text = [self.currentDisplayedDate dayString];
		headerView.monthLabel.text = [self.currentDisplayedDate localizedMonthShortString];
		headerView.wdayLabel.text = [self.currentDisplayedDate localizedWeekDayFullString];
		[headerView.leftButton addTarget:self.parentViewController action:@selector(handleSwipeRight:) forControlEvents:UIControlEventTouchUpInside];
		[headerView.rightButton addTarget:self.parentViewController action:@selector(handleSwipeLeft:) forControlEvents:UIControlEventTouchUpInside];
		[headerView.centerButton addTarget:self.parentViewController action:@selector(handleDateSelect:) forControlEvents:UIControlEventTouchUpInside];
		
		tbView.tableHeaderView = headerView;
		tbView.delegate = wSelf;
		tbView.dataSource = wSelf;
		return tbView;
		
	};
	
	setupTableView(self.tableView);
	
	UILongPressGestureRecognizer *longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenu:)];
	[self.view addGestureRecognizer:longPressGR];
	
}

- (void) viewWillAppear:(BOOL)animated {

//	[self fetchedResultsController];
	
	[super viewWillAppear:animated];
	
	
	[self refreshData];
	//[self restoreState];
	
	self.tableView.contentInset = UIEdgeInsetsZero;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMenuWillHide:) name:UIMenuControllerWillHideMenuNotification object:nil];
	
	IRTableView *tv = self.tableView;
	NSFetchedResultsController *frc = self.fetchedResultsController;
	
	for (NSIndexPath *ip in [tv indexPathsForVisibleRows]) {
		WAPostViewCellPhone *cell = (WAPostViewCellPhone *)[tv cellForRowAtIndexPath:ip];
		if ([cell isKindOfClass:[WAPostViewCellPhone class]]) {
			[cell setRepresentedObject:[frc objectAtIndexPath:ip]];
		}
	}

}

- (void) viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];
	
	if ([self scrollToTopmostPost]) {
		[[self tableView] scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
		[self setScrollToTopmostPost:NO];
	}

}

- (void) viewWillDisappear:(BOOL)animated {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerWillHideMenuNotification object:nil];

	NSArray *shownArticleIndexPaths = [self.tableView indexPathsForVisibleRows];

	NSArray *shownArticles = [shownArticleIndexPaths irMap: ^ (NSIndexPath *anIndexPath, NSUInteger index, BOOL *stop) {
		return [self.fetchedResultsController objectAtIndexPath:anIndexPath];
	}];
	
	NSArray *shownRowRects = [shownArticleIndexPaths irMap: ^ (NSIndexPath *anIndexPath, NSUInteger index, BOOL *stop) {
		return [NSValue valueWithCGRect:[self.tableView rectForRowAtIndexPath:anIndexPath]];
	}];
	
	__block WAArticle *sentArticle = [shownArticles count] ? [shownArticles objectAtIndex:0] : nil;
	
	if ([shownRowRects count] > 1) {
	
		//	If more than one rows were shown, find the first row that was fully visible
	
		[shownRowRects enumerateObjectsUsingBlock: ^ (NSValue *rectValue, NSUInteger idx, BOOL *stop) {
		
			CGRect rect = [rectValue CGRectValue];
			if (CGRectContainsRect(self.tableView.bounds, rect)) {
				sentArticle = [shownArticles objectAtIndex:idx];
				*stop = YES;
			}
			
		}];
	
	}
		
	[self.tableView resetPullDown];
	
	[super viewWillDisappear:animated];
	
}

- (void) viewDidUnload {

	[super viewDidUnload];

}

#pragma mark - 

- (void) didReceiveMemoryWarning {

	[super didReceiveMemoryWarning];
	
	[self removeCachedRowHeights];

}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	if ([self isViewLoaded])
	if (object == [WARemoteInterface sharedInterface])
		if ([[change objectForKey:NSKeyValueChangeNewKey] isEqual:(id)kCFBooleanFalse]) {
			[self.tableView performSelector:@selector(resetPullDown) withObject:nil afterDelay:2];
			
		}

}

#pragma mark - UITableView delegate/datasource protocol
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {

	return [[self.fetchedResultsController sections] count];
	
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	return [(id<NSFetchedResultsSectionInfo>)[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];

}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
		
  WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	WAPostViewCellPhone *cell = [WAPostViewCellPhone cellRepresentingObject:post inTableView:tableView];
	NSParameterAssert(cell.article == post);
	
	return cell;
	
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

	NSParameterAssert([NSThread isMainThread]);
	
	@autoreleasepool {
    
		WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
		NSCParameterAssert([post isKindOfClass:[WAArticle class]]);
		
		NSString *identifier = [WAPostViewCellPhone identifierRepresentingObject:post];
		
		id context = nil;
		CGFloat height = [self cachedRowHeightForObject:post context:&context];
		if (!height || ![context isEqual:identifier]) {
		
			height = [WAPostViewCellPhone heightForRowRepresentingObject:post inTableView:tableView];
			[self cacheRowHeight:height forObject:post context:identifier];
		
		}
	
		return height;
		
	}

}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSCParameterAssert([NSThread isMainThread]);
	NSCParameterAssert([self isViewLoaded]);
	NSCParameterAssert(self.view.window);
	
	UIMenuController *mc = [UIMenuController sharedMenuController];
	if ([mc isMenuVisible]) {
		
		[mc setMenuVisible:NO animated:YES];
		
		NSIndexPath *selectedRowIP = [tableView indexPathForSelectedRow];
		if (selectedRowIP)
			[tableView deselectRowAtIndexPath:selectedRowIP animated:YES];
		
		return;
		
	}

	WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
	NSCParameterAssert([post isKindOfClass:[WAArticle class]]);
	
	UIViewController *pushedVC = [WAArticleViewController controllerForArticle:post style:(WAFullScreenArticleStyle|WASuggestedStyleForArticle(post))];
	
	[self.navigationController pushViewController:pushedVC animated:YES];
	
}

- (IBAction) actionSettings:(id)sender {

  [self.settingsActionSheetController.managedActionSheet showFromBarButtonItem:sender animated:YES];

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)newOrientation {
  
	return newOrientation == UIInterfaceOrientationPortrait;
	
}

- (NSUInteger) supportedInterfaceOrientations {
	
	return UIInterfaceOrientationMaskPortrait;
	
}

- (void) refreshData {

	[[WARemoteInterface sharedInterface] rescheduleAutomaticRemoteUpdates];

}

#pragma mark - NSFetchedResultsController delegate protocol
- (void) controllerWillChangeContent:(NSFetchedResultsController *)controller {

	if (![self isViewLoaded])
		return;
	
	if (controller == self.fetchedResultsController) {
//		[self persistState];
		[self.tableView beginUpdates];
	}

}

- (void) controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {

	if (![self isViewLoaded])
		return;
		
	switch (type) {
		case NSFetchedResultsChangeDelete: {
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
			break;
		}
		case NSFetchedResultsChangeInsert: {
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
			break;
		}
		default: {
			NSParameterAssert(NO);
		}
	}

}

- (void) controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {

	[self removeCachedRowHeightForObject:anObject];

	if (![self isViewLoaded])
		return;
			
	switch (type) {
		case NSFetchedResultsChangeDelete: {
			NSParameterAssert(indexPath && !newIndexPath);
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
			break;
		}
		case NSFetchedResultsChangeInsert: {
			NSParameterAssert(!indexPath && newIndexPath);
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
			break;
		}
		case NSFetchedResultsChangeMove: {
		
			if (indexPath && newIndexPath) {
		
				NSParameterAssert(indexPath && newIndexPath);
				if ([self.tableView respondsToSelector:@selector(moveRowAtIndexPath:toIndexPath:)]) {
					[self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
				} else {
					[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
					[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
				}
			
			} else {
			
				NSParameterAssert(!indexPath && newIndexPath);
				[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
			
			}
			break;
		}
		case NSFetchedResultsChangeUpdate: {
			[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
			break;
		}
		
	}
	
}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {

	if (![self isViewLoaded])
		return;
	
	UITableView *tv = self.tableView;
	[tv endUpdates];
//	[self restoreState];
	
	NSArray *allVisibleIndexPaths = [tv indexPathsForVisibleRows];
	
	if ([allVisibleIndexPaths count]) {
	
		NSIndexPath *firstCellIndexPath = [allVisibleIndexPaths objectAtIndex:0];
		CGRect firstCellRect = [tv rectForRowAtIndexPath:firstCellIndexPath];
		
		if (tv.contentOffset.y < 0)
		if (!CGPointEqualToPoint(tv.frame.origin, [tv.superview convertPoint:firstCellRect.origin fromView:tv])) {
		
			[tv setContentOffset:CGPointZero animated:YES];
		
		}
	
	}
	
}

#pragma mark - 

- (BOOL) canBecomeFirstResponder {

	return [self isViewLoaded];

}

- (BOOL) canPerformAction:(SEL)anAction withSender:(id)sender {

	if (anAction == @selector(toggleFavorite:))
		return YES;
	
	if (anAction == @selector(editCoverImage:))
		return YES;
	
	if (anAction == @selector(removeArticle:))
		return YES;

#if TARGET_IPHONE_SIMULATOR
	
	if (anAction == @selector(makeDirty:))
		return YES;

#endif
	
	return NO;

}


#pragma mark - handle long pressed gesture
- (void) handleMenu:(UILongPressGestureRecognizer *)longPress {

	UIMenuController * const menuController = [UIMenuController sharedMenuController];
	if (menuController.menuVisible)
		return;
	
	BOOL didBecomeFirstResponder = [self becomeFirstResponder];
	NSAssert1(didBecomeFirstResponder, @"%s must require cell to become first responder", __PRETTY_FUNCTION__);

	NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[longPress locationInView:self.tableView]];
	WAArticle *article = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	WAPostViewCellPhone *cell = (WAPostViewCellPhone *
															 )[self.tableView cellForRowAtIndexPath:indexPath];
	NSParameterAssert(cell.article == article);	//	Bleh
	
	if (![cell isSelected])
		[self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	
	menuController.arrowDirection = UIMenuControllerArrowDown;
		
	NSMutableArray *menuItems = [NSMutableArray array];

#if TARGET_IPHONE_SIMULATOR

	[menuItems addObject:[[UIMenuItem alloc] initWithTitle:@"Make Dirty" action:@selector(makeDirty:)]];

#endif

	[menuItems addObject:[[UIMenuItem alloc] initWithTitle:([article.favorite isEqual:(id)kCFBooleanTrue] ?
		NSLocalizedString(@"ACTION_UNMARK_FAVORITE", @"Action marking article as not favorite") :
		NSLocalizedString(@"ACTION_MARK_FAVORITE", @"Action marking article as favorite")) action:@selector(toggleFavorite:)]];
	
	[menuItems addObject:[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"ACTION_DELETE", @"Action deleting an article") action:@selector(removeArticle:)]];
	
	if ([cell.article.files count] > 1)
		[menuItems addObject:[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"ACTION_CHANGE_REPRESENTING_FILE", @"Action changing representing file of an article") action:@selector(editCoverImage:)]];
	
	[menuController setMenuItems:menuItems];
	[menuController update];
	
	CGRect onScreenCellBounds = CGRectIntersection(cell.bounds, [self.tableView convertRect:self.tableView.bounds toView:cell]);
	
	[menuController setTargetRect:IRGravitize(onScreenCellBounds, (CGSize){ 8, 8}, kCAGravityCenter) inView:cell];
	[menuController setMenuVisible:YES animated:NO];
	
}

- (void) handleMenuWillHide:(NSNotification *)note {

	NSIndexPath *selectedRowIndexPath = [self.tableView indexPathForSelectedRow];

	if (selectedRowIndexPath)
		[self.tableView deselectRowAtIndexPath:selectedRowIndexPath animated:YES];

}

- (void) toggleFavorite:(id)sender {
	
	NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
	WAArticle *article = [self.fetchedResultsController objectAtIndexPath:selectedIndexPath];
	
	NSAssert1(selectedIndexPath && article, @"Selected index path %@ and underlying object must exist", selectedIndexPath);
	
	article.favorite = (NSNumber *)([article.favorite isEqual:(id)kCFBooleanTrue] ? kCFBooleanFalse : kCFBooleanTrue);
	article.dirty = (id)kCFBooleanTrue;
	if (article.modificationDate) {
		// set modification only when updating articles
		article.modificationDate = [NSDate date];
	}
	
	NSError *savingError = nil;
	if (![article.managedObjectContext save:&savingError])
		NSLog(@"Error saving: %@", savingError);
	
	[[WARemoteInterface sharedInterface] beginPostponingDataRetrievalTimerFiring];
	
	[[WADataStore defaultStore] updateArticle:[[article objectID] URIRepresentation] withOptions:nil onSuccess:^{
		
		[[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
		
	} onFailure:^(NSError *error) {
		
		[[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
		
	}];
	
}

- (void) editCoverImage:(id)sender {

	NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
	WAArticle *article = [self.fetchedResultsController objectAtIndexPath:selectedIndexPath];
	
	if (!selectedIndexPath || !article)
		return;
	
	__block WARepresentedFilePickerViewController *picker = [WARepresentedFilePickerViewController defaultAutoSubmittingControllerForArticle:[[article objectID] URIRepresentation] completion: ^ (NSURL *selectedFileURI) {
	
		[picker.navigationController dismissViewControllerAnimated:YES completion:nil];
		picker = nil;
		
	}];
	
	picker.navigationItem.leftBarButtonItem = [IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemCancel wiredAction:^(IRBarButtonItem *senderItem) {
	
		[picker.navigationController dismissViewControllerAnimated:YES completion:nil];
		picker = nil;
				
	}];
	
	WANavigationController *navC = [[WANavigationController alloc] initWithRootViewController:picker];
	[self.navigationController presentViewController:navC animated:YES completion:nil];
	
}

- (void) removeArticle:(id)sender {

	NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
	WAArticle *article = [self.fetchedResultsController objectAtIndexPath:selectedIndexPath];
	
	NSAssert1(selectedIndexPath && article, @"Selected index path %@ and underlying object must exist", selectedIndexPath);
	
	IRAction *cancelAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_CANCEL", @"Title for cancelling an action") block:nil];
	
	IRAction *deleteAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_DELETE", @"Title for deleting an article from the Timeline") block:^ {
	
		article.hidden = (id)kCFBooleanTrue;
		article.dirty = (id)kCFBooleanTrue;
		if (article.modificationDate) {
			// set modification only when updating articles
			article.modificationDate = [NSDate date];
		}
		
		NSError *savingError = nil;
		if (![article.managedObjectContext save:&savingError])
			NSLog(@"Error saving: %@", savingError);
		
		[[WARemoteInterface sharedInterface] beginPostponingDataRetrievalTimerFiring];
		
		[[WADataStore defaultStore] updateArticle:[[article objectID] URIRepresentation] withOptions:nil onSuccess:^{
			
			[[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
			
		} onFailure:^(NSError *error) {
			
			[[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
			
		}];
	
	}];
	
	NSString *deleteTitle = NSLocalizedString(@"DELETE_POST_CONFIRMATION_DESCRIPTION", @"Title for confirming a post deletion");
	
	IRActionSheetController *controller = [IRActionSheetController actionSheetControllerWithTitle:deleteTitle cancelAction:cancelAction destructiveAction:deleteAction otherActions:nil];
	
	[[controller managedActionSheet] showInView:self.navigationController.view];
		
}

- (void) makeDirty:(id)sender {

	NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
	WAArticle *article = [self.fetchedResultsController objectAtIndexPath:selectedIndexPath];
	
	NSAssert1(selectedIndexPath && article, @"Selected index path %@ and underlying object must exist", selectedIndexPath);
	
	article.dirty = (id)kCFBooleanTrue;
	[article.managedObjectContext save:nil];

}



- (void) handleFilter:(UIBarButtonItem *)sender {

	__block WAFilterPickerViewController *fpVC = [WAFilterPickerViewController controllerWithCompletion:^(NSFetchRequest *fr) {
	
		if (fr) {
		
			self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
			
			self.fetchedResultsController.delegate = self;
			[self.fetchedResultsController performFetch:nil];
			
			[self.tableView setContentOffset:CGPointZero animated:NO];
			[self.tableView reloadData];
		
		}
		
		[fpVC willMoveToParentViewController:nil];
		[fpVC removeFromParentViewController];
		[fpVC.view removeFromSuperview];
		[fpVC didMoveToParentViewController:nil];
		
		fpVC = nil;
		
	}];
	
	UIViewController *hostingVC = self.navigationController;
	if (!hostingVC)
		hostingVC = self;
	
	[hostingVC addChildViewController:fpVC];
	
	fpVC.view.frame = hostingVC.view.bounds;
	[hostingVC.view addSubview:fpVC.view];
	[fpVC didMoveToParentViewController:hostingVC];

}

@end
