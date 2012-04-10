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

#import "WAArticleDraftsViewController.h"
#import "WAViewController.h"
#import "WARepresentedFilePickerViewController.h"
#import "WAOverlayBezel.h"


static NSString * const WAPostsViewControllerPhone_RepresentedObjectURI = @"WAPostsViewControllerPhone_RepresentedObjectURI";

@interface WATimelineViewControllerPhone () <NSFetchedResultsControllerDelegate, WAImageStackViewDelegate, UIActionSheetDelegate, IASKSettingsDelegate, WAArticleDraftsViewControllerDelegate>

- (WAPulldownRefreshView *) defaultPulldownRefreshView;

@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) IRActionSheetController *settingsActionSheetController;

- (void) refreshData;

- (void) beginCompositionSessionWithURL:(NSURL *)anURL;

@end


@implementation WATimelineViewControllerPhone
@synthesize delegate;
@synthesize fetchedResultsController;
@synthesize managedObjectContext;
@synthesize settingsActionSheetController;

- (void) dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kWACompositionSessionRequestedNotification object:nil];
	[[WARemoteInterface sharedInterface] removeObserver:self forKeyPath:@"isPostponingDataRetrievalTimerFiring"];
  
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self)
		return nil;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCompositionSessionRequest:) name:kWACompositionSessionRequestedNotification object:nil];
		
	[[WARemoteInterface sharedInterface] addObserver:self forKeyPath:@"isPostponingDataRetrievalTimerFiring" options:NSKeyValueObservingOptionPrior|NSKeyValueObservingOptionNew context:nil];
  
	self.title = NSLocalizedString(@"APP_TITLE", @"Title for application");
	
	self.navigationItem.titleView = WAStandardTitleView();
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:WABarButtonImageFromImageNamed(@"WASettingsGlyph") style:UIBarButtonItemStylePlain target:self action:@selector(handleSettings:)];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:IRUIKitImage(@"UINavigationBarAddButton") style:UIBarButtonItemStylePlain target:self action:@selector(handleCompose:)];
		
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
	
	__weak WATimelineViewControllerPhone *nrSelf = self;
	
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
	
	settingsActionSheetController = [IRActionSheetController actionSheetControllerWithTitle:nil cancelAction:cancelAction destructiveAction:signOutAction otherActions:nil];

	return settingsActionSheetController;

}

- (NSManagedObjectContext *) managedObjectContext {

	if (managedObjectContext)
		return managedObjectContext;
	
	managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];

	return managedObjectContext;

}

- (NSFetchedResultsController *) fetchedResultsController {

	if (fetchedResultsController)
		return fetchedResultsController;

	NSFetchRequest *fr = [[WADataStore defaultStore] newFetchRequestForAllArticles];

	fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	
	fetchedResultsController.delegate = self;
  
  NSError *fetchingError;
	if (![fetchedResultsController performFetch:&fetchingError])
		NSLog(@"error fetching: %@", fetchingError);
		
	return fetchedResultsController;
	
}

- (WAPulldownRefreshView *) defaultPulldownRefreshView {

	return [WAPulldownRefreshView viewFromNib];
		
}

- (void) viewDidLoad {

	[super viewDidLoad];
		
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
	
	self.tableView.separatorColor = [UIColor colorWithRed:232.0/255.0 green:232/255.0 blue:226/255.0 alpha:1.0];
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	
	UILongPressGestureRecognizer *longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenu:)];
	[self.tableView addGestureRecognizer:longPressGR];
	
}

- (void) viewWillAppear:(BOOL)animated {
  
	[super viewWillAppear:animated];
  [self refreshData];
	
	self.tableView.contentInset = UIEdgeInsetsZero;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMenuWillHide:) name:UIMenuControllerWillHideMenuNotification object:nil];

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
	
	return [[UIView alloc] initWithFrame:CGRectZero];

}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	
	return [[UIView alloc] initWithFrame:CGRectZero];

}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {

	return 4;

}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {

	return 4;

}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
  WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  BOOL postHasFiles = (BOOL)!![post.files count];
  BOOL postHasPreview = (BOOL)!![post.previews count];
  
	WAPostViewCellPhone *cell;
	
	WAPostViewCellPhone * (^makeCell)(WAPostViewCellStyle) = ^ (WAPostViewCellStyle style) {
	
		NSString *identifier = ((NSString * []){
			[WAPostViewCellStyleDefault] = @"PostCell-TextOnly",
			[WAPostViewCellStyleImageStack] = @"PostCell-Stacked",
			[WAPostViewCellStyleWebLink] = @"PostCell-WebLink",
			[WAPostViewCellStyleWebLinkWithoutPhoto] = @"PostCell-WebLinkNoPhoto"
		})[style];
		
		WAPostViewCellPhone *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
		if (!cell)
			cell = [[WAPostViewCellPhone alloc] initWithPostViewCellStyle:style reuseIdentifier:identifier];
		
		return cell;
		
	};
	
	if (postHasPreview) {
	
		WAPreview *preview = [post.previews anyObject];
		cell = makeCell(preview.thumbnail ? WAPostViewCellStyleWebLink : WAPostViewCellStyleWebLinkWithoutPhoto);
		cell.post = post;
		
		cell.dateLabel.text = [[[IRRelativeDateFormatter sharedFormatter] stringFromDate:post.creationDate] lowercaseString];
		cell.commentLabel.attributedText = [cell.commentLabel attributedStringForString:post.text];
		cell.extraInfoLabel.text = @"";
	 
		cell.accessibilityLabel = @"Text";
		cell.accessibilityValue = post.text;

		cell.previewBadge.preview = preview;
		
		cell.accessibilityLabel = @"Preview";
		cell.accessibilityHint = preview.graphElement.title;
		cell.accessibilityValue = preview.graphElement.text;
		
		cell.previewImageView.image = preview.thumbnail;
		cell.previewTitleLabel.text = preview.graphElement.title;
		cell.previewProviderLabel.text = preview.graphElement.providerDisplayName;
		
//		cell.previewImageBackground.layer.shadowColor = [[UIColor grayColor] CGColor];
//		cell.previewImageBackground.layer.shadowOffset = CGSizeMake(0, 1.0);
//		cell.previewImageBackground.layer.shadowOpacity = 1.0f;
//		cell.previewImageBackground.layer.shadowRadius = 1.0f;
	
	} else if (postHasFiles) {

		cell = makeCell(WAPostViewCellStyleImageStack);
		cell.imageStackView.delegate = self;
		cell.commentLabel.userInteractionEnabled = YES;
		cell.post = post;
		cell.accessibilityLabel = @"Text";
		cell.accessibilityValue = post.text;
			
		objc_setAssociatedObject(cell.imageStackView, &WAPostsViewControllerPhone_RepresentedObjectURI, [[post objectID] URIRepresentation], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		
		[cell.imageStackView setImages:[[post.fileOrder subarrayWithRange:(NSRange){ 0, MIN([post.fileOrder count], 3) }] irMap: ^ (id inObject, NSUInteger index, BOOL *stop) {
			WAFile *file = (WAFile *)[post.managedObjectContext irManagedObjectForURI:inObject];
			return file.thumbnailImage;
		}] asynchronously:YES withDecodingCompletion:nil];
		
		if ([post.files count] > 3) {
			cell.extraInfoLabel.text = [NSString stringWithFormat:NSLocalizedString(@"NUMBER_OF_PHOTOS", @"Photo information in cell"), [post.files count]];
		}
	
		cell.accessibilityLabel = @"Photo";
		cell.accessibilityHint = [NSString stringWithFormat:@"%d photo(s)", [post.files count]];
  
  } else {
		
		cell = makeCell(WAPostViewCellStyleDefault);
		cell.post = post;
		
		cell.dateLabel.text = [[[IRRelativeDateFormatter sharedFormatter] stringFromDate:post.creationDate] lowercaseString];
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

	return height + ([post.files count] ? 250 : [post.previews count] ? 128 : 48);
	
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

	UIMenuController *menuController = [UIMenuController sharedMenuController];
	if ([menuController isMenuVisible]) {
		
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		if (indexPath)
			[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
		
		return;
		
	}
	
	WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
	NSURL *postURL = [[post objectID] URIRepresentation];
	BOOL photoPost = (BOOL)!![post.files count];
	
	__block UIViewController *pushedVC = nil;
  
	if([post.previews count])
		WAPostAppEvent(@"Create Preview", [NSDictionary dictionaryWithObjectsAndKeys:@"link",@"category",@"consume", @"action", nil]);
	else if([post.files count])
		WAPostAppEvent(@"Create Photo", [NSDictionary dictionaryWithObjectsAndKeys:@"photo",@"category",@"consume", @"action", nil]);
	else 
		WAPostAppEvent(@"Create Text", [NSDictionary dictionaryWithObjectsAndKeys:@"text",@"category",@"consume", @"action", nil]);
		
	if (photoPost) {
		
		pushedVC = [WAGalleryViewController controllerRepresentingArticleAtURI:postURL];
	
	} else {
		
		pushedVC = [WAArticleViewController controllerForArticle:postURL usingPresentationStyle:WAFullFrameArticleStyleFromDiscreteStyle([WAArticleViewController suggestedDiscreteStyleForArticle:post])];
	
	}
		
 	[self.navigationController pushViewController:pushedVC animated:YES];

}

- (void) beginCompositionSessionWithURL:(NSURL *)anURL {

	__block WACompositionViewController *compositionVC = [WACompositionViewController defaultAutoSubmittingCompositionViewControllerForArticle:anURL completion:^(NSURL *anURI) {
	
		[compositionVC dismissModalViewControllerAnimated:YES];
		compositionVC = nil;
		
	}];
	
  [self presentModalViewController:[compositionVC wrappingNavigationController] animated:YES];
	
}

- (BOOL) articleDraftsViewController:(WAArticleDraftsViewController *)aController shouldEnableArticle:(NSURL *)anObjectURIOrNil {

	return ![[WADataStore defaultStore] isUpdatingArticle:anObjectURIOrNil];

}

- (void) articleDraftsViewController:(WAArticleDraftsViewController *)aController didSelectArticle:(NSURL *)anObjectURIOrNil {

  [aController dismissViewControllerAnimated:YES completion:^{

		[self beginCompositionSessionWithURL:anObjectURIOrNil];
		
	}];

}

- (void) handleCompose:(UIBarButtonItem *)sender {

	if ([[WADataStore defaultStore] hasDraftArticles]) {
		
		WAArticleDraftsViewController *draftsVC = [[WAArticleDraftsViewController alloc] init];
		draftsVC.delegate = self;
		
		WANavigationController *navC = [[WANavigationController alloc] initWithRootViewController:draftsVC];
		//	((WANavigationBar *)navC.navigationBar).customBackgroundView = [WANavigationBar defaultPatternBackgroundView];
		
		__block __typeof__(self) nrSelf = self;
				
		draftsVC.navigationItem.leftBarButtonItem = [IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemCancel wiredAction:^(IRBarButtonItem *senderItem) {
			
			[nrSelf dismissViewControllerAnimated:YES completion:nil];
			
		}];
		
		[self presentModalViewController:navC animated:YES];
	
	} else {

		[self beginCompositionSessionWithURL:nil];
	
	}
  
}

- (void) handleSettings:(UIBarButtonItem *)sender  {

	WAUserInfoViewController *userInfoVC = [[WAUserInfoViewController alloc] init];
	
	__weak WATimelineViewControllerPhone *wSelf = self;
	__weak WAUserInfoViewController *wUserInfoVC = userInfoVC;
	
	userInfoVC.navigationItem.leftBarButtonItem = [IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemDone wiredAction:^(IRBarButtonItem *senderItem) {
		
		[wUserInfoVC.navigationController dismissViewControllerAnimated:YES completion:nil];
		
	}];
	
	userInfoVC.navigationItem.rightBarButtonItem =	[IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemAction wiredAction:^(IRBarButtonItem *senderItem) {
	
		[wSelf.settingsActionSheetController.managedActionSheet showFromBarButtonItem:wUserInfoVC.navigationItem.rightBarButtonItem animated:YES];
			
	}];
	
	UINavigationController *wrappingNavC = [[WANavigationController alloc] initWithRootViewController:userInfoVC];
	[self presentViewController:wrappingNavC animated:YES completion:nil];
	
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
				
				return (WAArticle *)nil;
				
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
	
	return NO;

	//	In the future, this will prove handy
	//
	//	if ([super canPerformAction:anAction withSender:sender])
	//		return YES;
	//	
	//	if ([self respondsToSelector:anAction])
	//		return YES;
	//	
	//	return NO;

}

- (void) handleMenu:(UILongPressGestureRecognizer *)longPress {

	UIMenuController * const menuController = [UIMenuController sharedMenuController];
	if (menuController.menuVisible)
		return;
	
	BOOL didBecomeFirstResponder = [self becomeFirstResponder];
	NSAssert1(didBecomeFirstResponder, @"%s must require cell to become first responder", __PRETTY_FUNCTION__);

	NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[longPress locationInView:self.tableView]];
	WAArticle *article = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	WAPostViewCellPhone *cell = (WAPostViewCellPhone *)[self.tableView cellForRowAtIndexPath:indexPath];
	NSParameterAssert(cell.post == article);	//	Bleh
	
	if (![cell isSelected])
		[self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	
	menuController.arrowDirection = UIMenuControllerArrowDown;
		
	NSMutableArray *menuItems = [NSMutableArray array];
		
	[menuItems addObject:[[UIMenuItem alloc] initWithTitle:([article.favorite isEqual:(id)kCFBooleanTrue] ?
		NSLocalizedString(@"ACTION_UNMARK_FAVORITE", @"Action marking article as not favorite") :
		NSLocalizedString(@"ACTION_MARK_FAVORITE", @"Action marking article as favorite")) action:@selector(toggleFavorite:)]];
	
	[menuItems addObject:[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"ACTION_DELETE", @"Action deleting an article") action:@selector(removeArticle:)]];
	
	if ([cell.post.files count] > 1)
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
	article.modificationDate = [NSDate date];
	
	NSError *savingError = nil;
	if (![article.managedObjectContext save:&savingError])
		NSLog(@"Error saving: %@", savingError);
	
	[[WARemoteInterface sharedInterface] beginPostponingDataRetrievalTimerFiring];
	
	[[WADataStore defaultStore] updateArticle:[[article objectID] URIRepresentation] withOptions:[NSDictionary dictionaryWithObjectsAndKeys:
		
		(id)kCFBooleanTrue, kWADataStoreArticleUpdateShowsBezels,
		
	nil] onSuccess:^{
		
		[[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
		
	} onFailure:^(NSError *error) {
		
		[[WARemoteInterface sharedInterface] endPostponingDataRetrievalTimerFiring];
		
	}];

}

- (void) editCoverImage:(id)sender {

	NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
	WAArticle *article = [self.fetchedResultsController objectAtIndexPath:selectedIndexPath];
	
	NSAssert1(selectedIndexPath && article, @"Selected index path %@ and underlying object must exist", selectedIndexPath);
	
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
	
}

@end
