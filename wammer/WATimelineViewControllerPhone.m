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
	
	if (postHasPreview) {
		
		WAPreview *latestPreview = (WAPreview *)[[[post.previews allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:
			[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES],
		nil]] lastObject];
		
		identifier = webLinkCellIdentifier;
		style = WAPostViewCellStyleWebLink;
		if (!latestPreview.thumbnail) {
			identifier = webLinkCellWithoutPhotoIdentifier;
			style = WAPostViewCellStyleWebLinkWithoutPhoto;
		}
		
		cell = (WAPostViewCellPhone *)[tableView dequeueReusableCellWithIdentifier:identifier];
		if (!cell) {
			cell = [[WAPostViewCellPhone alloc] initWithPostViewCellStyle:style reuseIdentifier:identifier];
			cell.commentLabel.userInteractionEnabled = YES;
		}
		cell.post = post;
		
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
		cell.previewProviderLabel.text = latestPreview.graphElement.providerDisplayName;
		
		cell.previewImageBackground.layer.shadowColor = [[UIColor grayColor] CGColor];
		cell.previewImageBackground.layer.shadowOffset = CGSizeMake(0, 1.0);
		cell.previewImageBackground.layer.shadowOpacity = 1.0f;
		cell.previewImageBackground.layer.shadowRadius = 1.0f;
	
	} else if (postHasFiles) {
	
		cell = (WAPostViewCellPhone *)[tableView dequeueReusableCellWithIdentifier:imageCellIdentifier];
		if (!cell) {
			cell = [[WAPostViewCellPhone alloc] initWithPostViewCellStyle:WAPostViewCellStyleImageStack reuseIdentifier:imageCellIdentifier];
			cell.imageStackView.delegate = self;
			cell.commentLabel.userInteractionEnabled = YES;
		}
		cell.post = post;
		
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
			
			cell = [[WAPostViewCellPhone alloc] initWithPostViewCellStyle:WAPostViewCellStyleDefault reuseIdentifier:textOnlyCellIdentifier];
			cell.imageStackView.delegate = self;
			cell.commentLabel.userInteractionEnabled = YES;
			
			UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenu:)];
			[cell addGestureRecognizer:longPress];

					
		}
		cell.post = post;
		
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

	return ![[WADataStore defaultStore] isUploadingArticle:anObjectURIOrNil];

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

	if ([super canPerformAction:anAction withSender:sender])
		return YES;
		
	if ([self respondsToSelector:anAction])
		return YES;
	
	return NO;

}

- (void) handleMenu:(UILongPressGestureRecognizer *)longPress {

	UIMenuController * const menuController = [UIMenuController sharedMenuController];
	if (menuController.menuVisible)
		return;
	
	BOOL didBecomeFirstResponder = [self becomeFirstResponder];
	NSAssert1(didBecomeFirstResponder, @"%s must require cell to become first responder", __PRETTY_FUNCTION__);

	WAPostViewCellPhone *cell = (WAPostViewCellPhone *)[self.tableView cellForRowAtIndexPath:[self.tableView indexPathForRowAtPoint:[longPress locationInView:self.tableView]]];
	menuController.arrowDirection = UIMenuControllerArrowDown;
		
	NSMutableArray *menuItems = [NSMutableArray array];
	[menuItems addObject:[[UIMenuItem alloc] initWithTitle:@"Favorite" action:@selector(favorite:)]];
	[menuItems addObject:[[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(remove:)]];
	
	if ([cell.post.files count] > 2)
		[menuItems addObject:[[UIMenuItem alloc] initWithTitle:@"Choose Cover" action:@selector(cover:)]];
	
	[menuController setMenuItems:menuItems];
	[menuController update];
	
	[menuController setTargetRect:cell.frame inView:cell.superview];
	[menuController setMenuVisible:YES animated:YES];
	
}

- (void) favorite:(id)sender {
	NSLog(@"Cell was favorited");
}

- (void) cover:(id)sender {
	NSLog(@"Cell was cover");
}

- (void) remove:(id)sender {
	NSLog(@"Cell was removed");
}

@end
