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
#import "WAPostsViewControllerPhone.h"
#import "WACompositionViewController.h"
#import "WAPaginationSlider.h"

#import "WARemoteInterface.h"
#import "WARemoteInterface+ScheduledDataRetrieval.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "IRPaginatedView.h"
#import "IRBarButtonItem.h"
#import "IRTransparentToolbar.h"
#import "IRActionSheetController.h"
#import "IRActionSheet.h"
#import "IRAction.h"
#import "IRAlertView.h"

#import "WAArticleViewController.h"
#import "WAPostViewControllerPhone.h"

#import "WAArticleCommentsViewCell.h"
#import "WAPostViewCellPhone.h"
#import "WAComposeViewControllerPhone.h"

#import "WAGalleryViewController.h"

#import "WAPulldownRefreshView.h"

#import "WAApplicationDidReceiveReadingProgressUpdateNotificationView.h"
#import "IRTableView.h"


static NSString * const WAPostsViewControllerPhone_RepresentedObjectURI = @"WAPostsViewControllerPhone_RepresentedObjectURI";

@interface WAPostsViewControllerPhone () <NSFetchedResultsControllerDelegate, WAImageStackViewDelegate, UIActionSheetDelegate>

- (UIView *) defaultTitleView;
- (WAPulldownRefreshView *) defaultPulldownRefreshView;

@property (nonatomic, readwrite, retain) WAApplicationDidReceiveReadingProgressUpdateNotificationView *readingProgressUpdateNotificationView;

@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) NSString *_lastID;
@property (nonatomic, readwrite, retain) IRActionSheetController *settingsActionSheetController;

- (void) refreshData;
- (void) syncLastRead:(NSIndexPath *)indexPath;
- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize FromImage:(UIImage *)sourceImage;
+ (IRRelativeDateFormatter *) relativeDateFormatter;

- (void) beginCompositionSessionWithURL:(NSURL *)anURL;

- (void) setLastScannedObject:(WAArticle *)anArticle completion:(void(^)(BOOL didFinish))callback;
- (void) retrieveLastScannedObjectWithCompletion:(void(^)(WAArticle *anArticleOrNil))callback;

@end


@implementation WAPostsViewControllerPhone
@synthesize delegate;
@synthesize fetchedResultsController;
@synthesize managedObjectContext;
@synthesize _lastID;
@synthesize settingsActionSheetController;
@synthesize readingProgressUpdateNotificationView;

- (void) dealloc {
	
	[managedObjectContext release];
	[fetchedResultsController release];
  [_lastID release];
	[readingProgressUpdateNotificationView release];

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
  
	self.title = NSLocalizedString(@"WAAppTitle", @"Title for application");
	
	__block __typeof__(self) nrSelf = self;
	
	self.navigationItem.leftBarButtonItem = [IRBarButtonItem itemWithButton:WAButtonForImage(WABarButtonImageFromImageNamed(@"WAFilter")) wiredAction: ^ (UIButton *senderButton, IRBarButtonItem *senderItem) {
		[nrSelf performSelector:@selector(actionSettings:) withObject:senderItem];
	}];
	
	self.navigationItem.rightBarButtonItem = [IRBarButtonItem itemWithButton:WAButtonForImage(WABarButtonImageFromImageNamed(@"WACompose")) wiredAction: ^ (UIButton *senderButton, IRBarButtonItem *senderItem) {
		[nrSelf performSelector:@selector(handleCompose:) withObject:senderItem];
	}];
	
	self.navigationItem.titleView = [self defaultTitleView];
	
	return self;
  
}

- (UIView *) defaultTitleView {

	UIImageView *logotype = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"WALogo"]] autorelease];
	logotype.contentMode = UIViewContentModeScaleAspectFit;
	logotype.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	logotype.frame = (CGRect){ CGPointZero, (CGSize){ 128, 40 }};
	
	UIView *containerView = [[UIView alloc] initWithFrame:(CGRect){	CGPointZero, (CGSize){ 128, 44 }}];
	logotype.frame = IRGravitize(containerView.bounds, logotype.bounds.size, kCAGravityResizeAspect);
	[containerView addSubview:logotype];
	
	return containerView;

}

- (IRActionSheetController *) settingsActionSheetController {

	if (settingsActionSheetController)
		return settingsActionSheetController;
	
	__block __typeof(self) nrSelf = self;
	
	settingsActionSheetController = [[IRActionSheetController actionSheetControllerWithTitle:@"Settings"
		cancelAction:[IRAction actionWithTitle:@"Cancel" block:nil]
		destructiveAction:nil 
		otherActions:[NSArray arrayWithObjects:
			
			[IRAction actionWithTitle:@"Sign Out" block:^{
			
				[[IRAlertView alertViewWithTitle:@"Sign Out" message:@"Really sign out?" cancelAction:[IRAction actionWithTitle:@"Cancel" block:nil] otherActions:
					
					[NSArray arrayWithObjects:
						[IRAction actionWithTitle:@"Sign Out" block: ^ {
							[nrSelf.delegate applicationRootViewControllerDidRequestReauthentication:nrSelf];
						}],
					nil]
					
				] show];
			
			}], 
			
			[IRAction actionWithTitle:@"Change API URL" block:^ {
				
				[nrSelf.delegate applicationRootViewControllerDidRequestChangeAPIURL:nrSelf];
				
			}],
			
	nil]] retain];

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

	fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:(( ^ {
		
		NSFetchRequest *fetchRequest = [self.managedObjectContext.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRArticles" substitutionVariables:[NSDictionary dictionary]];
		fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
			[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO],
		nil];
		
		return fetchRequest;
		
	})()) managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	
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
	
	UIView *pulldownHeaderBackground = [[[UIView alloc] initWithFrame:UIEdgeInsetsInsetRect(pulldownHeader.bounds, (UIEdgeInsets){ -256, 0, 0, 0 })] autorelease];
	pulldownHeaderBackground.backgroundColor = [UIColor colorWithWhite:0 alpha:0.125];
	
	IRGradientView *pulldownHeaderBackgroundShadow = [[[IRGradientView alloc] initWithFrame:IRGravitize(
		pulldownHeader.bounds,
		(CGSize){ CGRectGetWidth(pulldownHeader.bounds), 3 },
		kCAGravityBottom
	)] autorelease];
	
	UIColor *fromColor = [UIColor colorWithWhite:0 alpha:0];
	UIColor *toColor = [UIColor colorWithWhite:0 alpha:0.125];
	
	[pulldownHeaderBackgroundShadow setLinearGradientFromColor:fromColor anchor:irTop toColor:toColor anchor:irBottom];
	
	[pulldownHeader addSubview:pulldownHeaderBackground];
	[pulldownHeader addSubview:pulldownHeaderBackgroundShadow];
	[pulldownHeader sendSubviewToBack:pulldownHeaderBackgroundShadow];
	[pulldownHeader sendSubviewToBack:pulldownHeaderBackground];
	
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
	self.tableView.backgroundColor = nil;
	self.tableView.opaque = NO;
	
	
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
		
		actualBackgroundView.bounds = (CGRect){
			CGPointZero,
			(CGSize){
				CGRectGetWidth(tableViewBounds),
				backgroundImageSize.height * ceilf((3 * CGRectGetHeight(tableViewBounds)) / backgroundImageSize.height)
			}
		};
		
		actualBackgroundView.center = (CGPoint){
			0.5 * CGRectGetWidth(tableViewBounds),
			
			0.5 * (CGRectGetHeight(actualBackgroundView.bounds) - CGRectGetHeight(tableViewBounds)) + 
			-1 * remainderf(tableViewContentOffset.y, backgroundImageSize.height) + 
			0 * fmodf(
				backgroundImageSize.height - fmodf(tableViewContentOffset.y, backgroundImageSize.height) - CGRectGetHeight(tableViewBounds),
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
	
	//	?
	
	[self retrieveLastScannedObjectWithCompletion: ^ (WAArticle *anArticleOrNil) {
	
		if (![self isViewLoaded])
			return;
			
		__block __typeof__(self) nrSelf = self;
		__block __typeof__(self.readingProgressUpdateNotificationView) nrNotificationView = self.readingProgressUpdateNotificationView;
		
		self.readingProgressUpdateNotificationView.onAction = ^ {
		
			nrNotificationView.onAction = nil;
			
			[nrNotificationView enqueueAnimationForVisibility:NO completion:^(BOOL didFinish) {
			
				//	nil
			
			}];
			
			NSIndexPath *objectIndexPath = [self.fetchedResultsController indexPathForObject:anArticleOrNil];
			
			if (objectIndexPath)
				[nrSelf.tableView scrollToRowAtIndexPath:objectIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
				
		};
		
		self.readingProgressUpdateNotificationView.onClear = ^ {
		
			[nrNotificationView enqueueAnimationForVisibility:NO completion:^(BOOL didFinish) {
				
				//	nil
				
			}];
		
		};
		
		[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
		
		[self.readingProgressUpdateNotificationView enqueueAnimationForVisibility:YES completion:^(BOOL didFinish) {

			[[UIApplication sharedApplication] endIgnoringInteractionEvents];
			
		}];
			
	}];

}

- (void) viewWillDisappear:(BOOL)animated {

	WAArticle *bottomMostArticle = [[[self.tableView indexPathsForVisibleRows] irMap: ^ (NSIndexPath *anIndexPath, NSUInteger index, BOOL *stop) {
	
		return [self.fetchedResultsController objectAtIndexPath:anIndexPath];
		
	}] lastObject];
	
	[self setLastScannedObject:bottomMostArticle completion:^(BOOL didFinish) {
	
		NSLog(@"setLastScannedObject -> %x", didFinish);
		
	}];
  	
	[super viewWillDisappear:animated];
	
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	if ([self isViewLoaded])
	if (object == [WARemoteInterface sharedInterface])
	if ([[change objectForKey:NSKeyValueChangeNewKey] isEqual:(id)kCFBooleanFalse])
		[self.tableView resetPullDown];

}

- (void) handleCompositionSessionRequest:(NSNotification *)incomingNotification {

	if (![self isViewLoaded])
		return;

	NSURL *contentURL = [[incomingNotification userInfo] objectForKey:@"foundURL"];
	[self beginCompositionSessionWithURL:contentURL];
	
}

- (void) syncLastRead:(NSIndexPath *)indexPath {
  
	NSString *currentRowIdentifier = [[self.fetchedResultsController objectAtIndexPath:indexPath] identifier];
	
  [[WARemoteInterface sharedInterface] setLastReadArticleRemoteIdentifier:currentRowIdentifier  onSuccess:^(NSDictionary *response) {
  } onFailure:^(NSError *error) {
    NSLog(@"SetLastRead failed %@", error);
  }];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return [[self.fetchedResultsController sections] count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [(id<NSFetchedResultsSectionInfo>)[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  static NSString *textOnlyCellIdentifier = @"PostCell-TextOnly";
  static NSString *imageCellIdentifier = @"PostCell-Stacked";
  static NSString *webLinkCellIdentifier = @"PostCell-WebLink";
  
  BOOL postHasFiles = (BOOL)!![post.files count];
  BOOL postHasPreview = (BOOL)!![post.previews count];
  
  NSString *identifier = 
		postHasFiles ? imageCellIdentifier : 
		postHasPreview ? webLinkCellIdentifier : 
		textOnlyCellIdentifier;
	
  WAPostViewCellStyle style = 
		postHasFiles ? WAPostViewCellStyleImageStack : 
		postHasPreview ? WAPostViewCellStyleWebLink : 
		WAPostViewCellStyleDefault;
	
  WAPostViewCellPhone *cell = (WAPostViewCellPhone *)[tableView dequeueReusableCellWithIdentifier:identifier];
  if (!cell) {
		
    cell = [[WAPostViewCellPhone alloc] initWithPostViewCellStyle:style reuseIdentifier:identifier];
    cell.imageStackView.delegate = self;
		cell.commentLabel.userInteractionEnabled = YES;
		cell.backgroundColor = nil;
		cell.opaque = NO;
		
  }
	
  cell.userNicknameLabel.text = post.owner.nickname;//[[post.owner.nickname componentsSeparatedByString: @" "] objectAtIndex:0];
  cell.avatarView.image = post.owner.avatar;
  cell.dateLabel.text = [[[[self class] relativeDateFormatter] stringFromDate:post.timestamp] lowercaseString];
	cell.commentLabel.attributedText = [cell.commentLabel attributedStringForString:post.text];
 
  if (postHasPreview) {
	
		WAPreview *latestPreview = (WAPreview *)[[[post.previews allObjects] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:
			[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES],
		nil]] lastObject];	
		
		[cell.previewBadge configureWithPreview:latestPreview];
		
  } else {
	
		[cell.previewBadge configureWithPreview:nil];	//	?
	
	}
    
  if (postHasFiles) {
    
		objc_setAssociatedObject(cell.imageStackView, &WAPostsViewControllerPhone_RepresentedObjectURI, [[post objectID] URIRepresentation], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  
		NSArray *allImages = [post.fileOrder irMap: ^ (id inObject, NSUInteger index, BOOL *stop) {
      WAFile *file = (WAFile *)[post.managedObjectContext irManagedObjectForURI:inObject];
			return file.thumbnailImage;
		}];
		
		NSArray *firstTwoImages = [allImages subarrayWithRange:(NSRange){ 0, MIN(2, [allImages count] )}];
		
		[cell.imageStackView setImages:firstTwoImages asynchronously:YES withDecodingCompletion:nil];	//	?
	
	} else {
	
		[cell.imageStackView setImages:nil asynchronously:NO withDecodingCompletion:nil];
	
	}
  
  return cell;
  
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
	UIFont *baseFont = [UIFont fontWithName:@"Helvetica" size:14.0];
  CGFloat height = [post.text sizeWithFont:baseFont constrainedToSize:(CGSize){
		CGRectGetWidth(tableView.frame) - 80,
		9999.0
	} lineBreakMode:UILineBreakModeWordWrap].height;

	return height + ([post.files count] ? 222 : [post.previews count] ? 164 : 64);
	
}

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize FromImage:(UIImage *)sourceImage {

	return [sourceImage irScaledImageWithSize:targetSize];

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

//- (void) controllerWillChangeContent:(NSFetchedResultsController *)controller {
//
//	if (![self isViewLoaded])
//		return;
//	
//	[self.tableView beginUpdates];
//	
//}
//
//- (void) controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
//
//	switch (type) {
//		case NSFetchedResultsChangeInsert: {
//			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
//			break;
//		}
//		case NSFetchedResultsChangeDelete: {
//			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
//			break;
//		}
//		case NSFetchedResultsChangeMove: {
//			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
//			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
//			break;
//		}
//		case NSFetchedResultsChangeUpdate: {
//			[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
//			break;
//		}
//	}
//
//}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
		
	if (![self isViewLoaded])
		return;
		
	[self persistState];
	[self.tableView reloadData];
	[self restoreState];
		
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	[self syncLastRead:indexPath];
	
	WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
	WAPostViewControllerPhone *controller = [WAPostViewControllerPhone controllerWithPost:[[post objectID] URIRepresentation]];

	[self.navigationController pushViewController:controller animated:YES];
	
}

- (void) beginCompositionSessionWithURL:(NSURL *)anURL {

  WAComposeViewControllerPhone *composeViewController = [WAComposeViewControllerPhone controllerWithWebPost:anURL completion:^(NSURL *aPostURLOrNil) {
    
		[[WADataStore defaultStore] uploadArticle:aPostURLOrNil onSuccess: ^ {
			//	We’ll get a save, do nothing
			//	dispatch_async(dispatch_get_main_queue(), ^ {
			//		[self refreshData];
			//	});
		} onFailure:nil];
		
	}];
  
  UINavigationController *navigationController = [[[UINavigationController alloc]initWithRootViewController:composeViewController]autorelease];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentModalViewController:navigationController animated:YES];
	
}

- (void) handleCompose:(UIBarButtonItem *)sender {

	[self beginCompositionSessionWithURL:nil];
  
}

+ (IRRelativeDateFormatter *) relativeDateFormatter {
  
	return [IRRelativeDateFormatter sharedFormatter];
  
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

	[[WARemoteInterface sharedInterface] updateLastScannedPostInGroup:anArticle.group.identifier withPost:anArticle.identifier onSuccess: ^ {
	
		if (callback)
			callback(YES);
		 
 } onFailure: ^ (NSError *error) {
 
		if (callback)
		callback(NO);
	 
 }];

}

- (void) retrieveLastScannedObjectWithCompletion:(void(^)(WAArticle *anArticleOrNil))callback {

	NSString * aGroupIdentifier = [[NSSet setWithArray:[self.fetchedResultsController.fetchedObjects irMap: ^ (WAArticle *anArticle, NSUInteger index, BOOL *stop) {
		
		return anArticle.group.identifier;
		
	}]] anyObject];
	
	__block __typeof__(self) nrSelf = self;

	[[WARemoteInterface sharedInterface] retrieveLastScannedPostInGroup:aGroupIdentifier onSuccess:^(NSString *lastScannedPostIdentifier) {
	
		dispatch_async(dispatch_get_main_queue(), ^{
			
			WAArticle *matchingArticle = [[nrSelf.fetchedResultsController.fetchedObjects irMap: ^ (WAArticle *anArticle, NSUInteger index, BOOL *stop) {
			
				if ([anArticle.identifier isEqualToString:lastScannedPostIdentifier])
					return anArticle;
				
				return nil;
				
			}] lastObject];
			
			if (callback)
				callback(matchingArticle);
		
		});

	} onFailure:^(NSError *error) {
	
		dispatch_async(dispatch_get_main_queue(), ^{

			if (callback)
				callback(nil);
			
		});
		
	}];

}

@end
