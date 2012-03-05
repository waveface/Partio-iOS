//
//  WAArticlesViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <objc/runtime.h>

#import "WADefines.h"

#import "WADataStore.h"
#import "WATimelineViewControllerPhone.h"
#import "WACompositionViewController.h"
#import "WAPaginationSlider.h"

#import "WARemoteInterface.h"

#import "UIKit+IRAdditions.h"

#import "WAArticleViewController.h"
#import "WAPostViewControllerPhone.h"

#import "WAArticleCommentsViewCell.h"
#import "WAPostViewCellPhone.h"

#import "WAGalleryViewController.h"
#import "WAPulldownRefreshView.h"

#import "WAApplicationDidReceiveReadingProgressUpdateNotificationView.h"

#import "WAUserInfoViewController.h"
#import "WANavigationController.h"
#import "IASKAppSettingsViewController.h"

#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "WACompositionViewController+CustomUI.h"
#import "WANavigationBar.h"

static NSString * const WAPostsViewControllerPhone_RepresentedObjectURI = @"WAPostsViewControllerPhone_RepresentedObjectURI";

@interface WATimelineViewControllerPhone () <NSFetchedResultsControllerDelegate, WAImageStackViewDelegate, UIActionSheetDelegate, IASKSettingsDelegate>

- (WAPulldownRefreshView *) defaultPulldownRefreshView;

@property (nonatomic, readwrite, retain) WAApplicationDidReceiveReadingProgressUpdateNotificationView *readingProgressUpdateNotificationView;

@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) IRActionSheetController *settingsActionSheetController;

- (void) refreshData;

- (void) beginCompositionSessionWithURL:(NSURL *)anURL;

@property (nonatomic, readwrite, retain) NSString *lastScannedObjectIdentifier;
@property (nonatomic, readwrite, retain) NSString *lastUserReactedScannedObjectIdentifier;
- (void) setLastScannedObject:(WAArticle *)anArticle completion:(void(^)(BOOL didFinish))callback;
- (void) retrieveLastScannedObjectWithCompletion:(void(^)(NSString *articleIdentifier, WAArticle *anArticleOrNil))callback;

- (BOOL) handleIncomingLastScannedObjectIdentifier:(NSString *)anIdentifier;
- (void) scrollToArticle:(WAArticle *)anArticle;

@end


@implementation WATimelineViewControllerPhone
@synthesize delegate;
@synthesize fetchedResultsController;
@synthesize managedObjectContext;
@synthesize settingsActionSheetController;
@synthesize readingProgressUpdateNotificationView;
@synthesize lastScannedObjectIdentifier, lastUserReactedScannedObjectIdentifier;

- (void) dealloc {
	
	[managedObjectContext release];
	[fetchedResultsController release];
	[readingProgressUpdateNotificationView release];
  [lastScannedObjectIdentifier release];
	[lastUserReactedScannedObjectIdentifier release];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:kWACompositionSessionRequestedNotification object:nil];
	[[WARemoteInterface sharedInterface] removeObserver:self forKeyPath:@"isPostponingDataRetrievalTimerFiring"];
		
	[super dealloc];
  
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self)
		return nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCompositionSessionRequest:) name:kWACompositionSessionRequestedNotification object:nil];
		
	[[WARemoteInterface sharedInterface] addObserver:self forKeyPath:@"isPostponingDataRetrievalTimerFiring" options:NSKeyValueObservingOptionPrior|NSKeyValueObservingOptionNew context:nil];
  
	self.title = NSLocalizedString(@"APP_TITLE", @"Title for application");
	
	if (YES) {
	
		__block __typeof__(self) nrSelf = self;
	
		self.navigationItem.titleView = WAStandardTitleView();
		
		self.navigationItem.leftBarButtonItem = WABarButtonItem([UIImage imageNamed:@"WASettingsGlyph"], nil, ^{
			
			[nrSelf handleSettings:nil];
							
		}),
		
		self.navigationItem.rightBarButtonItem = WABarButtonItem([UIImage imageNamed:@"WACompose"], nil, ^{
			
			[nrSelf performSelector:@selector(handleCompose:) withObject:nil];
			
		});
	
	} else {
	
		self.navigationItem.titleView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
		
		self.navigationItem.leftBarButtonItem = [IRBarButtonItem itemWithCustomView:WAStandardTitleView()];
		
		self.navigationItem.rightBarButtonItem = [IRBarButtonItem itemWithCustomView:((^ {
		
			__block __typeof__(self) nrSelf = self;
				
			IRTransparentToolbar *toolbar = [[[IRTransparentToolbar alloc] initWithFrame:(CGRect){ 0, 0, 110, 44 }] autorelease];
			
			toolbar.items = [NSArray arrayWithObjects:
			
				WABarButtonItem([UIImage imageNamed:@"WAUserGlyph"], nil, ^{
					
						[nrSelf handleSettings:nil];
									
				}),
				
				WABarButtonItem([UIImage imageNamed:@"WACompose"], nil, ^{
					
					[nrSelf performSelector:@selector(handleCompose:) withObject:nil];
					
				}),
			
			nil];
			
			return toolbar;
		
		})())];
	
	}
			
	return self;
  
}

- (void) irConfigure {

	[super irConfigure];
	
	self.persistsContentInset = NO;

}





- (NSString *) persistenceIdentifier {

	return NSStringFromClass([self class]);

}





NSString * const kWAPostsViewControllerLastVisibleObjectURIs = @"WAPostsViewControllerLastVisiblePostURIs";
NSString * const kWAPostsViewControllerLastVisibleRects = @"WAPostsViewControllerLastVisibleRects";

- (NSMutableDictionary *) persistenceRepresentation {

	NSMutableDictionary *answer = [super persistenceRepresentation];
	NSLog(@"%s: %@", __PRETTY_FUNCTION__, answer);
	
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
	
	__block __typeof(self) nrSelf = self;
	
	IRAction *cancelAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_CANCEL", nil) block:nil];
	IRAction *signOutAction = [IRAction actionWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", nil) block:^{
	
		NSString *alertTitle = NSLocalizedString(@"ACTION_SIGN_OUT", nil);
		NSString *alertText = NSLocalizedString(@"SIGN_OUT_CONFIRMATION", nil);
		
		[[IRAlertView alertViewWithTitle:alertTitle message:alertText cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:
			
			[IRAction actionWithTitle:NSLocalizedString(@"ACTION_SIGN_OUT", nil) block: ^ {
				
				[nrSelf.delegate applicationRootViewControllerDidRequestReauthentication:nil];
				
			}],
			
		nil]] show];
		
	}];
	
	settingsActionSheetController = [[IRActionSheetController actionSheetControllerWithTitle:nil cancelAction:cancelAction destructiveAction:signOutAction otherActions:nil] retain];

	return settingsActionSheetController;

}

- (NSManagedObjectContext *) managedObjectContext {

	if (managedObjectContext)
		return managedObjectContext;
	
	managedObjectContext = [[[WADataStore defaultStore] defaultAutoUpdatedMOC] retain];

	return managedObjectContext;

}

- (NSFetchedResultsController *) fetchedResultsController {

	if (fetchedResultsController)
		return fetchedResultsController;

	NSFetchRequest *fr = [[[WADataStore defaultStore] newFetchRequestForAllArticles] autorelease];

	fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	
	fetchedResultsController.delegate = self;
  
  NSError *fetchingError;
	if (![fetchedResultsController performFetch:&fetchingError])
		NSLog(@"error fetching: %@", fetchingError);
		
	return fetchedResultsController;
	
}

- (void) viewDidUnload {
		
	self.readingProgressUpdateNotificationView = nil;
	
	[super viewDidUnload];
	
}

- (WAPulldownRefreshView *) defaultPulldownRefreshView {

	__block WAPulldownRefreshView *pulldownHeader = [WAPulldownRefreshView viewFromNib];
	
	return pulldownHeader;
		
}

- (WAApplicationDidReceiveReadingProgressUpdateNotificationView *) readingProgressUpdateNotificationView {

	if (readingProgressUpdateNotificationView)
		return readingProgressUpdateNotificationView;
		
	readingProgressUpdateNotificationView = [[WAApplicationDidReceiveReadingProgressUpdateNotificationView viewFromNib] retain];
	readingProgressUpdateNotificationView.hidden = YES;
	
	return readingProgressUpdateNotificationView;

}

- (void) viewDidLoad {

	[super viewDidLoad];
		
	__block __typeof__(self) nrSelf = self;
	
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		
	WAPulldownRefreshView *pulldownHeader = [self defaultPulldownRefreshView];
	
	self.tableView.pullDownHeaderView = pulldownHeader;
	self.tableView.onPullDownMove = ^ (CGFloat progress) {
		[pulldownHeader setProgress:progress animated:YES];	
	};
	self.tableView.onPullDownEnd = ^ (BOOL didFinish) {
		if (didFinish) {
			pulldownHeader.progress = 0;
			[pulldownHeader setBusy:YES animated:YES];
			[[WARemoteInterface sharedInterface] performAutomaticRemoteUpdatesNow];
		}
	};
	self.tableView.onPullDownReset = ^ {
		[pulldownHeader setBusy:NO animated:YES];
	};
	
	
	__block UIView *backgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
	self.tableView.backgroundView = backgroundView;
	
	__block UIView *actualBackgroundView = [[[UIView alloc] initWithFrame:backgroundView.bounds] autorelease];
	[backgroundView addSubview:actualBackgroundView];
	UIImage *backgroundImage = [UIImage imageNamed:@"WABackground"];
	CGSize backgroundImageSize = backgroundImage.size;
	actualBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	actualBackgroundView.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
	
	__block WAApplicationDidReceiveReadingProgressUpdateNotificationView *progressUpdateNotification = [self readingProgressUpdateNotificationView];
	
	progressUpdateNotification.bounds = (CGRect){
		CGPointZero,
		(CGSize){
			CGRectGetWidth(self.tableView.bounds),
			progressUpdateNotification.bounds.size.height
		}
	};
	
	[self.tableView addSubview:progressUpdateNotification];
	
	
	self.tableView.onLayoutSubviews = ^ {
	
		CGRect tableViewBounds = nrSelf.tableView.bounds;
		CGPoint tableViewContentOffset = nrSelf.tableView.contentOffset;
		UIEdgeInsets tableViewContentInset = [nrSelf.tableView actualContentInset];
		
		nrSelf.tableView.scrollIndicatorInsets = tableViewContentInset;
		
		actualBackgroundView.bounds = (CGRect){
			CGPointZero,
			(CGSize){
				CGRectGetWidth(tableViewBounds),
				backgroundImageSize.height * ceilf((3 * CGRectGetHeight(tableViewBounds)) / backgroundImageSize.height)
			}
		};
		
		actualBackgroundView.center = (CGPoint){
			
			0.5 * CGRectGetWidth(tableViewBounds),

			backgroundImageSize.height + remainderf(
				0.5 * CGRectGetHeight(actualBackgroundView.bounds) - remainderf(tableViewContentOffset.y, backgroundImageSize.height),
				backgroundImageSize.height
			)
			
		};
		
		nrSelf.readingProgressUpdateNotificationView.center = (CGPoint){
			tableViewContentOffset.x + 0.5 * CGRectGetWidth(tableViewBounds),
			tableViewContentOffset.y + 0.5 * CGRectGetHeight(nrSelf.readingProgressUpdateNotificationView.bounds)
		};
		
	};
	
}

- (void) viewWillAppear:(BOOL)animated {
  
	[super viewWillAppear:animated];
  [self refreshData];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:animated];
	
	self.readingProgressUpdateNotificationView.hidden = YES;
	self.tableView.contentInset = UIEdgeInsetsZero;

}

- (void) viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];
	
	self.tableView.contentInset = UIEdgeInsetsZero;
	self.readingProgressUpdateNotificationView.hidden = YES;
	self.readingProgressUpdateNotificationView.onAction = nil;
	self.readingProgressUpdateNotificationView.onClear = nil;

	__block __typeof__(self) nrSelf = self;
	__block __typeof__(self.readingProgressUpdateNotificationView) nrNotificationView = self.readingProgressUpdateNotificationView;
	
	CFAbsoluteTime beforeLastScannedObjectRetrieval = CFAbsoluteTimeGetCurrent();
	
	void (^presentInterface)(NSString *) = ^ (NSString *incomingIdentifier) {
	
		CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
		CFTimeInterval elapsedTime = (currentTime - beforeLastScannedObjectRetrieval);
		
		if (![nrSelf handleIncomingLastScannedObjectIdentifier:incomingIdentifier])
			return;
			
		if (elapsedTime <= 3) {
		
			if (![nrSelf.lastUserReactedScannedObjectIdentifier isEqualToString:incomingIdentifier]) {
		
				NSLog(@"autoscroll, nrSelf.lastUserReactedScannedObjectIdentifier -> %@", incomingIdentifier);
				
				nrSelf.lastUserReactedScannedObjectIdentifier = incomingIdentifier;
				
				[[WADataStore defaultStore] fetchArticleWithIdentifier:incomingIdentifier usingContext:nrSelf.managedObjectContext onSuccess:^(NSString *identifier, WAArticle *article) {

					[nrSelf.fetchedResultsController performFetch:nil];
					[nrSelf.tableView reloadData];
					
					[nrSelf scrollToArticle:article];
					
				}];
			
			}
			
			return;
			
		} else {
		
			if (nrNotificationView.hidden) {
			
				[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
				
				[nrNotificationView enqueueAnimationForVisibility:YES withAdditionalAnimation:^{
				
					UIEdgeInsets newInsets = self.tableView.contentInset;
					newInsets.top += CGRectGetHeight(nrNotificationView.bounds);
					self.tableView.contentInset = newInsets;
					[nrSelf.tableView layoutSubviews];
								
				} completion: ^ (BOOL didFinish) {

					[[UIApplication sharedApplication] endIgnoringInteractionEvents];
					
				}];
			
			}
		
		}
		
	};
	
	[self retrieveLastScannedObjectWithCompletion: ^ (NSString *incomingIdentifier, WAArticle *anArticleOrNil) {
	
		NSLog(@"retrieveLastScannedObjectWithCompletion -> %@", incomingIdentifier);
	
		if (!incomingIdentifier)
			return;
	
		nrSelf.lastScannedObjectIdentifier = anArticleOrNil.identifier;
	
		if (![nrSelf isViewLoaded])
			return;
		
		if (anArticleOrNil) {
			presentInterface(incomingIdentifier);
			return;
		}
		
		[[WARemoteInterface sharedInterface] beginPostponingDataRetrievalTimerFiring];
		
		[WAArticle synchronizeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:
			kWAArticleSyncFullyFetchOnlyStrategy, kWAArticleSyncStrategy,
		nil] completion:^(BOOL didFinish, NSManagedObjectContext *temporalContext, NSArray *prospectiveUnsavedObjects, NSError *anError) {
		
			dispatch_async(dispatch_get_main_queue(), ^{
				
				if (didFinish) {
				
					NSError *savingError = nil;
					if (![temporalContext save:&savingError])
						NSLog(@"Error saving: %@", savingError);
					
					[[WADataStore defaultStore] fetchArticleWithIdentifier:incomingIdentifier usingContext:temporalContext onSuccess:^(NSString *identifier, WAArticle *article) {
					
						if (!article) {
							nrSelf.lastUserReactedScannedObjectIdentifier = incomingIdentifier;
							return;
						}
						
						presentInterface(incomingIdentifier);
						
					}];
				
				}
				
				[[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
			
			});
			
		}];
		
		//	?
		
	}];

}

- (BOOL) handleIncomingLastScannedObjectIdentifier:(NSString *)incomingIdentifier {

	__block __typeof__(self) nrSelf = self;
	__block __typeof__(self.readingProgressUpdateNotificationView) nrNotificationView = self.readingProgressUpdateNotificationView;
	
	if ([self.lastUserReactedScannedObjectIdentifier isEqualToString:self.lastScannedObjectIdentifier])
		return NO;
	
	nrNotificationView.onAction = ^ {
	
		NSLog(@"self.lastUserReactedScannedObjectIdentifier -> %@", nrSelf.lastUserReactedScannedObjectIdentifier);
		nrSelf.lastUserReactedScannedObjectIdentifier = incomingIdentifier;
	
		[nrNotificationView enqueueAnimationForVisibility:NO withAdditionalAnimation:^{
			
			UIEdgeInsets newInsets = self.tableView.contentInset;
			newInsets.top -= CGRectGetHeight(nrNotificationView.bounds);
			self.tableView.contentInset = newInsets;
			[nrSelf.tableView layoutSubviews];
			
		} completion:nil];
		
		[[WADataStore defaultStore] fetchArticleWithIdentifier:incomingIdentifier usingContext:nrSelf.managedObjectContext onSuccess:^(NSString *identifier, WAArticle *article) {
		
			//	Fixme: MOMENTARILY HIGHLGIGHT THE CELL
		
			[nrSelf scrollToArticle:article];
			
		}];
		
		nrNotificationView.onAction = nil;
		
	};
	
	nrNotificationView.onClear = ^ {
	
		NSLog(@"self.lastUserReactedScannedObjectIdentifier -> %@", nrSelf.lastUserReactedScannedObjectIdentifier);
		nrSelf.lastUserReactedScannedObjectIdentifier = incomingIdentifier;
		
		[nrNotificationView enqueueAnimationForVisibility:NO withAdditionalAnimation:^{
			
			UIEdgeInsets newInsets = nrSelf.tableView.contentInset;
			newInsets.top -= CGRectGetHeight(nrNotificationView.bounds);
			nrSelf.tableView.contentInset = newInsets;
			[nrSelf.tableView layoutSubviews];
			
		} completion:nil];
		
		nrNotificationView.onClear = nil;
		
	};
	
	return YES;
	
}

- (void) scrollToArticle:(WAArticle *)anArticleOrNil {

	NSParameterAssert(anArticleOrNil.managedObjectContext == self.managedObjectContext);
	NSIndexPath *objectIndexPath = [self.fetchedResultsController indexPathForObject:anArticleOrNil];
	
	if (objectIndexPath) {
	
			CGRect objectRect = [self.tableView rectForRowAtIndexPath:objectIndexPath];
			
			if (CGRectEqualToRect(CGRectIntersection(objectRect, self.tableView.bounds), CGRectNull)) {
			
				//	Only scroll if the cell is not already shown
			
				[self.tableView setContentOffset:(CGPoint){
					self.tableView.contentOffset.x,
					MAX(0, objectRect.origin.y - 24)
				} animated:YES];
			
			}
			
	}

}

- (void) viewWillDisappear:(BOOL)animated {

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
	
	//	NSString *newLastScannedObjectIdentifier = sentArticle.identifier;
	
	[self setLastScannedObject:sentArticle completion:^(BOOL didFinish) {
		
		//	Don’t go back to what we have said
		//	self.lastScannedObjectIdentifier = newLastScannedObjectIdentifier;
		//	self.lastUserReactedScannedObjectIdentifier = newLastScannedObjectIdentifier;
		
	}];
	
	self.readingProgressUpdateNotificationView.onAction = nil;
	self.readingProgressUpdateNotificationView.onClear = nil;
	
	[self.tableView resetPullDown];
	//	self.tableView.contentOffset = UIEdgeInsetsZero;
	
	[super viewWillDisappear:animated];
	
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	if ([self isViewLoaded])
	if (object == [WARemoteInterface sharedInterface])
	if ([[change objectForKey:NSKeyValueChangeNewKey] isEqual:(id)kCFBooleanFalse])
		[self.tableView performSelector:@selector(resetPullDown) withObject:nil afterDelay:2];

}

- (void) handleCompositionSessionRequest:(NSNotification *)incomingNotification {

	if (![self isViewLoaded])
		return;

	NSURL *contentURL = [[incomingNotification userInfo] objectForKey:@"foundURL"];
	[self beginCompositionSessionWithURL:contentURL];
	
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {

	return [[self.fetchedResultsController sections] count];
	
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	return [(id<NSFetchedResultsSectionInfo>)[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
	
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	return [[[UIView alloc] initWithFrame:CGRectZero] autorelease];

}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	
	return [[[UIView alloc] initWithFrame:CGRectZero] autorelease];

}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {

	return 4;

}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {

	return 4;

}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *textOnlyCellIdentifier = @"PostCell-TextOnly";
	static NSString *imageCellIdentifier = @"PostCell-Stacked";
	static NSString *webLinkCellIdentifier = @"PostCell-WebLink";
  static NSString *webLinkCellWithoutPhotoIdentifier = @"PostCell-WebLinkNoPhoto";
  
  WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  BOOL postHasFiles = (BOOL)!![post.files count];
  BOOL postHasPreview = (BOOL)!![post.previews count];
  
  NSString *identifier;
	WAPostViewCellStyle style;
	WAPostViewCellPhone *cell;
	
	// TODO: put these logic into cell.
	if (postHasPreview) {
		WAPreview *latestPreview = (WAPreview *)[[[post.previews allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:
			[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES],
		nil]] lastObject];
		
		identifier = webLinkCellIdentifier;
		style = WAPostViewCellStyleWebLink;
  	if(latestPreview.thumbnail == 0){
			identifier = webLinkCellWithoutPhotoIdentifier;
			style = WAPostViewCellStyleWebLinkWithoutPhoto;
		}
		
		cell = (WAPostViewCellPhone *)[tableView dequeueReusableCellWithIdentifier:identifier];
		if (!cell) {
			cell = [[[WAPostViewCellPhone alloc] initWithPostViewCellStyle:style reuseIdentifier:identifier] autorelease];
			cell.commentLabel.userInteractionEnabled = YES;
		}
		
		cell.dateLabel.text = [[[IRRelativeDateFormatter sharedFormatter] stringFromDate:post.timestamp] lowercaseString];
		cell.commentLabel.attributedText = [cell.commentLabel attributedStringForString:post.text];
		cell.extraInfoLabel.text = @"";
	 
		cell.accessibilityLabel = @"Text";
		cell.accessibilityValue = post.text;

		cell.previewBadge.preview = latestPreview;
		
		cell.accessibilityLabel = @"Preview";
		cell.accessibilityHint = latestPreview.graphElement.title;
		cell.accessibilityValue = latestPreview.graphElement.text;
		
		cell.previewImageView.image = latestPreview.thumbnail;
		cell.previewTitleLabel.text = latestPreview.graphElement.title;
		cell.previewProviderLabel.text = latestPreview.graphElement.providerURL;
		
		cell.previewImageBackground.layer.shadowColor = [[UIColor grayColor] CGColor];
		cell.previewImageBackground.layer.shadowOffset = CGSizeMake(0, 1.0);
		cell.previewImageBackground.layer.shadowOpacity = 1.0f;
		cell.previewImageBackground.layer.shadowRadius = 1.0f;
	
	} else if (postHasFiles) {
	
		cell = (WAPostViewCellPhone *)[tableView dequeueReusableCellWithIdentifier:imageCellIdentifier];
		if (!cell) {
			
			cell = [[[WAPostViewCellPhone alloc] initWithPostViewCellStyle:WAPostViewCellStyleImageStack reuseIdentifier:imageCellIdentifier] autorelease];
			cell.imageStackView.delegate = self;
			cell.commentLabel.userInteractionEnabled = YES;
					
		}
		
		cell.dateLabel.text = [[[IRRelativeDateFormatter sharedFormatter] stringFromDate:post.timestamp] lowercaseString];
		cell.commentLabel.attributedText = [cell.commentLabel attributedStringForString:post.text];
		cell.extraInfoLabel.text = @"";
	 
		cell.accessibilityLabel = @"Text";
		cell.accessibilityValue = post.text;
			
		objc_setAssociatedObject(cell.imageStackView, &WAPostsViewControllerPhone_RepresentedObjectURI, [[post objectID] URIRepresentation], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		
		[cell.imageStackView setImages:[[post.fileOrder subarrayWithRange:(NSRange){ 0, MIN([post.fileOrder count], 3) }] irMap: ^ (id inObject, NSUInteger index, BOOL *stop) {
			WAFile *file = (WAFile *)[post.managedObjectContext irManagedObjectForURI:inObject];
			return file.thumbnailImage;
		}] asynchronously:YES withDecodingCompletion:nil];
		
		if ([post.files count] > 3){
			cell.extraInfoLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NUMBER_OF_PHOTOS", @"Photo information in cell"), [post.files count]];
		}
	
		cell.accessibilityLabel = @"Photo";
		cell.accessibilityHint = [NSString stringWithFormat:@"%d photo(s)", [post.files count]];
  
  } else {
		cell = (WAPostViewCellPhone *)[tableView dequeueReusableCellWithIdentifier:textOnlyCellIdentifier];
		if (!cell) {
			
			cell = [[[WAPostViewCellPhone alloc] initWithPostViewCellStyle:WAPostViewCellStyleDefault reuseIdentifier:textOnlyCellIdentifier] autorelease];
			cell.imageStackView.delegate = self;
			cell.commentLabel.userInteractionEnabled = YES;
					
		}
		
		cell.dateLabel.text = [[[IRRelativeDateFormatter sharedFormatter] stringFromDate:post.timestamp] lowercaseString];
		cell.commentLabel.attributedText = [cell.commentLabel attributedStringForString:post.text];
		cell.extraInfoLabel.text = @"";
	 
		cell.accessibilityLabel = @"Text";
		cell.accessibilityValue = post.text;
	}
	return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  
	WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	UIFont *baseFont = [UIFont fontWithName:@"Helvetica" size:14.0];
  CGFloat height = [post.text sizeWithFont:baseFont constrainedToSize:(CGSize){
		CGRectGetWidth(tableView.frame) - 80,
		140.0  // 6 lines
	} lineBreakMode:UILineBreakModeWordWrap].height;

	return height + ([post.files count] ? 250 : [post.previews count] ? 128 : 36);
	
}

- (IBAction) actionSettings:(id)sender {

  [self.settingsActionSheetController.managedActionSheet showFromBarButtonItem:sender animated:YES];

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)newOrientation {
  
  return newOrientation == UIInterfaceOrientationPortrait;	
	
}

- (void) refreshData {

	[[WARemoteInterface sharedInterface] rescheduleAutomaticRemoteUpdates];

}

- (void) controllerWillChangeContent:(NSFetchedResultsController *)controller {

	if (![self isViewLoaded])
		return;
		
	[UIView setAnimationsEnabled:NO];
	
	[self persistState];
	[self.tableView beginUpdates];

}

- (void) controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {

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

	NSParameterAssert([NSThread isMainThread]);

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
			NSParameterAssert(indexPath && !newIndexPath);
			[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
			break;
		}
		
	}

}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
	
	if (![self isViewLoaded])
		return;
		
	[self.tableView endUpdates];
	[self restoreState];
	
	[UIView setAnimationsEnabled:YES];
		
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
	NSURL *postURL = [[post objectID] URIRepresentation];
	BOOL photoPost = (BOOL)!![post.files count];
	
	__block UIViewController *pushedVC = nil;
  
	if (photoPost) {
		
		pushedVC = [WAGalleryViewController controllerRepresentingArticleAtURI:postURL];
		
		pushedVC.navigationItem.leftBarButtonItem = WATransparentBlackBackBarButtonItem([UIImage imageNamed:@"WABackGlyph"], nil, ^ {
			
			[pushedVC.navigationController popViewControllerAnimated:YES];
		
		});
	
	} else {
		
		pushedVC = [WAArticleViewController controllerForArticle:postURL usingPresentationStyle:WAFullFrameArticleStyleFromDiscreteStyle([WAArticleViewController suggestedDiscreteStyleForArticle:post])];
		
		pushedVC.navigationItem.leftBarButtonItem = WABackBarButtonItem([UIImage imageNamed:@"WABackGlyph"], nil, ^ {
			
			[pushedVC.navigationController popViewControllerAnimated:YES];
		
		});
	
	}

	//	Instead of this…
	//	
	//		NSString *articleTitle = post.text;
	//		if (![[articleTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
	//			articleTitle = @"Post";
	//		
	//		self.navigationItem.backBarButtonItem = [IRBarButtonItem itemWithTitle:articleTitle action:nil];
	//		
	//		__block __typeof__(self) nrSelf = self; 
	//		galleryViewController.onDismiss = ^ {
	//			
	//			nrSelf.navigationItem.backBarButtonItem = nil;
	//			
	//		};
		
	pushedVC.navigationItem.hidesBackButton = YES;
		
	[self.navigationController pushViewController:pushedVC animated:YES];

}

- (void) beginCompositionSessionWithURL:(NSURL *)anURL {

	__block WACompositionViewController *compositionVC = [WACompositionViewController defaultAutoSubmittingCompositionViewControllerForArticle:anURL completion:^(NSURL *anURI) {
	
		[compositionVC dismissModalViewControllerAnimated:YES];
		
	}];
	
  [self presentModalViewController:[compositionVC wrappingNavigationController] animated:YES];
	
}

- (void) handleCompose:(UIBarButtonItem *)sender {

	[self beginCompositionSessionWithURL:nil];
  
}

- (void) handleSettings:(UIBarButtonItem *)sender  {

	WAUserInfoViewController *userInfoVC = [[[WAUserInfoViewController alloc] init] autorelease];
	UINavigationController *wrappingNavC = [[[WANavigationController alloc] initWithRootViewController:userInfoVC] autorelease];
	
	__block __typeof__(self) nrSelf = self;
	
	userInfoVC.navigationItem.leftBarButtonItem = WABarButtonItem(nil, NSLocalizedString(@"ACTION_DONE", nil), ^{
		
		[wrappingNavC dismissModalViewControllerAnimated:YES];
		
	});
	
	__block UIBarButtonItem *actionItem = WABarButtonItem([UIImage imageNamed:@"WAActionGlyph"], nil, ^{
		
		[nrSelf.settingsActionSheetController.managedActionSheet showFromBarButtonItem:actionItem animated:YES];
			
	});
	
	userInfoVC.navigationItem.rightBarButtonItem = actionItem;
	
	wrappingNavC.navigationBar.tintColor = [UIColor brownColor];
	[((WANavigationBar *)wrappingNavC.navigationBar) setCustomBackgroundView:[WANavigationBar defaultPatternBackgroundView]];
	[self presentModalViewController:wrappingNavC animated:YES];
	
}

- (void) imageStackView:(WAImageStackView *)aStackView didRecognizePinchZoomGestureWithRepresentedImage:(UIImage *)representedImage contentRect:(CGRect)aRect transform:(CATransform3D)layerTransform {
  
	NSURL *representedObjectURI = objc_getAssociatedObject(aStackView, &WAPostsViewControllerPhone_RepresentedObjectURI);
	
	__block __typeof__(self) nrSelf = self;
	__block WAGalleryViewController *galleryViewController = nil;
	galleryViewController = [WAGalleryViewController controllerRepresentingArticleAtURI:representedObjectURI];
	galleryViewController.hidesBottomBarWhenPushed = YES;
	galleryViewController.onDismiss = ^ {
    
		CATransition *transition = [CATransition animation];
		transition.duration = 0.3f;
		transition.type = kCATransitionPush;
		transition.subtype = ((^ {
			switch (self.interfaceOrientation) {
				case UIInterfaceOrientationPortrait:
					return kCATransitionFromLeft;
				case UIInterfaceOrientationPortraitUpsideDown:
					return kCATransitionFromRight;
				case UIInterfaceOrientationLandscapeLeft:
					return kCATransitionFromTop;
				case UIInterfaceOrientationLandscapeRight:
					return kCATransitionFromBottom;
			}
		})());
		transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		transition.fillMode = kCAFillModeForwards;
		transition.removedOnCompletion = YES;
    
		[galleryViewController.navigationController setNavigationBarHidden:NO animated:NO];
		[galleryViewController.navigationController popViewControllerAnimated:NO];
		
		[nrSelf.navigationController.view.layer addAnimation:transition forKey:@"transition"];
	};
	
	CATransition *transition = [CATransition animation];
	transition.duration = 0.3f;
	transition.type = kCATransitionPush;
	transition.subtype = ((^ {
		switch (self.interfaceOrientation) {
			case UIInterfaceOrientationPortrait:
				return kCATransitionFromRight;
			case UIInterfaceOrientationPortraitUpsideDown:
				return kCATransitionFromLeft;
			case UIInterfaceOrientationLandscapeLeft:
				return kCATransitionFromBottom;
			case UIInterfaceOrientationLandscapeRight:
				return kCATransitionFromTop;
		}
	})());
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	transition.fillMode = kCAFillModeForwards;
	transition.removedOnCompletion = YES;
	
	[self.navigationController setNavigationBarHidden:YES animated:NO];
	[self.navigationController pushViewController:galleryViewController animated:NO];
	
	[self.navigationController.view.layer addAnimation:transition forKey:@"transition"];
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
  
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, transition.duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
	});
	
}

- (void) setLastScannedObject:(WAArticle *)anArticle completion:(void(^)(BOOL didFinish))callback {

	if (!anArticle)
		return;

	[[WARemoteInterface sharedInterface] updateLastScannedPostInGroup:anArticle.group.identifier withPost:anArticle.identifier onSuccess: ^ {
	
		if (callback)
			callback(YES);
		 
 } onFailure: ^ (NSError *error) {
 
		if (callback)
		callback(NO);
	 
 }];

}

- (void) retrieveLastScannedObjectWithCompletion:(void(^)(NSString *articleIdentifier, WAArticle *anArticleOrNil))callback {

	NSString * aGroupIdentifier = [[NSSet setWithArray:[self.fetchedResultsController.fetchedObjects irMap: ^ (WAArticle *anArticle, NSUInteger index, BOOL *stop) {
		
		return anArticle.group.identifier;
		
	}]] anyObject];

	if (!aGroupIdentifier)
		aGroupIdentifier = [WARemoteInterface sharedInterface].primaryGroupIdentifier;
	
	__block __typeof__(self) nrSelf = self;

	[[WARemoteInterface sharedInterface] retrieveLastScannedPostInGroup:aGroupIdentifier onSuccess:^(NSString *lastScannedPostIdentifier) {
	
		dispatch_async(dispatch_get_main_queue(), ^{
			
			WAArticle *matchingArticle = [[nrSelf.fetchedResultsController.fetchedObjects irMap: ^ (WAArticle *anArticle, NSUInteger index, BOOL *stop) {
			
				if ([anArticle.identifier isEqualToString:lastScannedPostIdentifier])
					return anArticle;
				
				return nil;
				
			}] lastObject];
			
			if (callback)
				callback(lastScannedPostIdentifier, matchingArticle);
		
		});

	} onFailure:^(NSError *error) {
	
		dispatch_async(dispatch_get_main_queue(), ^{

			if (callback)
				callback(nil, nil);
			
		});
		
	}];

}

@end
