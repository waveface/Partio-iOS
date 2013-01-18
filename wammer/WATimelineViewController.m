//
//  WATimelineViewControllerPadViewController.m
//  wammer
//
//  Created by Shen Steven on 11/20/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WATimelineViewController.h"
#import "WATimelineViewCell.h"
#import "WADayHeaderView.h"
#import "WAEventViewController.h"

#import "WARemoteInterface.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "WANavigationController.h"
#import "NSDate+WAAdditions.h"
#import "WAAppearance.h"
#import "QuartzCore+IRAdditions.h"

#import "WARepresentedFilePickerViewController.h"
#import "WARepresentedFilePickerViewController+CustomUI.h"
#import "IRBarButtonItem.h"
#import "IRAction.h"
#import "IRActionSheet.h"
#import "IRActionSheetController.h"
#import "WADayViewController.h"
#import "WACalendarPickerViewController.h"
#import "Kal.h"

@interface WATimelineViewController () <NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIPopoverControllerDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowlayout;

@property (nonatomic, strong) NSDate *currentDisplayedDate;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) UIPopoverController *calendarPopoverForIPad;

@property (nonatomic, readwrite, retain) UILongPressGestureRecognizer *longPressGR;

@property (nonatomic, strong) NSMutableArray *objectsChanged;

@end

@implementation WATimelineViewController {
  CGFloat (^rowSpacing) (UICollectionView *);
}

- (id) initWithDate:(NSDate*)date {
	
  self = [super initWithNibName:nil bundle:nil];
  if (!self)
	return nil;

  self.currentDisplayedDate = [date copy];
	
  self.flowlayout = [[UICollectionViewFlowLayout alloc] init];
  self.flowlayout.itemSize = (CGSize) {320, 310};
  self.flowlayout.scrollDirection = UICollectionViewScrollDirectionVertical;
  
  CGRect rect = (CGRect) { CGPointZero, self.view.frame.size };
  self.collectionView = [[UICollectionView alloc] initWithFrame:rect collectionViewLayout:self.flowlayout];
  
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  self.collectionView.autoresizesSubviews = YES;
  
  self.collectionView.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];
  
  [self.collectionView registerNib:[[self class] nibForDayHeader] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"WADayHeaderView"];
  [self.collectionView registerNib:[[self class] nibForImageStack1] forCellWithReuseIdentifier:@"PostCell-Photo-1"];
  [self.collectionView registerNib:[[self class] nibForImageStack2] forCellWithReuseIdentifier:@"PostCell-Photo-2"];
  [self.collectionView registerNib:[[self class] nibForImageStack3] forCellWithReuseIdentifier:@"PostCell-Photo-3"];
  [self.collectionView registerNib:[[self class] nibForCheckinOnly] forCellWithReuseIdentifier:@"PostCell-Checkin"];
  
  self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  [self.view addSubview:self.collectionView];
  self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  self.longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenu:)];
  [self.collectionView addGestureRecognizer:self.longPressGR];
  
  self.objectsChanged = [NSMutableArray array];
  
  rowSpacing = ^ (UICollectionView *collectionView) {
	
	CGFloat width = CGRectGetWidth(collectionView.frame);
	CGFloat itemWidth = ((UICollectionViewFlowLayout*)collectionView.collectionViewLayout).itemSize.width;
	int numCell = (int)(width / itemWidth);
	
	CGFloat w = ((int)((int)(width) % (int)(itemWidth))) / (numCell + 1);
	
	return w;
  };
  
  return self;
	
}

+ (UINib*) nibForDayHeader {
  static UINib *nib = nil;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nib = [UINib nibWithNibName:@"WADayHeaderView" bundle:nil];
  });
  
  return nib;
}

+ (UINib*) nibForImageStack1 {
  static UINib *nib = nil;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nib = [UINib nibWithNibName:@"WATimelineViewCell-ImageStack-1" bundle:nil];
  });
  
  return nib;
}

+ (UINib*) nibForImageStack2 {
  static UINib *nib = nil;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nib = [UINib nibWithNibName:@"WATimelineViewCell-ImageStack-2" bundle:nil];
  });
  
  return nib;
}

+ (UINib*) nibForImageStack3 {
  static UINib *nib = nil;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nib = [UINib nibWithNibName:@"WATimelineViewCell-ImageStack-3" bundle:nil];
  });
  
  return nib;
}

+ (UINib*) nibForCheckinOnly {
  static UINib *nib = nil;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nib = [UINib nibWithNibName:@"WATimelineViewCell-Checkin" bundle:nil];
  });
  
  return nib;
}


- (void) viewDidAppear:(BOOL)animated {
	
  [super viewDidAppear:animated];
  self.fetchedResultsController.delegate = self;
  [self.collectionView reloadData];
  
}

- (void) viewWillDisappear:(BOOL)animated {
  
  [super viewWillDisappear:animated];
  self.fetchedResultsController.delegate = nil;
  
}

- (void)didReceiveMemoryWarning
{
	
    [super didReceiveMemoryWarning];
	
}


- (NSUInteger) supportedInterfaceOrientations {
	
	return  [self.parentViewController supportedInterfaceOrientations];
	
}

- (BOOL) shouldAutorotate {

	return YES;
	
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	[self.collectionView.collectionViewLayout invalidateLayout];
	
}

- (NSManagedObjectContext*) managedObjectContext {
  
  if (_managedObjectContext)
	return _managedObjectContext;
  
  _managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
  
  return  _managedObjectContext;
  
}

- (NSFetchedResultsController*) fetchedResultsController {
  
  if (_fetchedResultsController)
	return _fetchedResultsController;

  if (!self.currentDisplayedDate)
	self.currentDisplayedDate = [NSDate date];
  
  NSFetchRequest *fr = [[WADataStore defaultStore] newFetchRequestForArticlesOnDate:self.currentDisplayedDate];
  
  NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"yyyy-MM-dd" options:0 locale:[NSLocale currentLocale] ];
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:formatString];
  
  NSString *cacheName = [NSString stringWithFormat:@"fetchedTableCache-%@", [formatter stringFromDate:self.currentDisplayedDate]];
  _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:cacheName];
  _fetchedResultsController.delegate = self;
  
  NSError *fetchingError;
  if (![_fetchedResultsController performFetch:&fetchingError])
	NSLog(@"error fetching: %@", fetchingError);
  
  return _fetchedResultsController;

}

- (void) dealloc {
  
  [self.collectionView removeGestureRecognizer:self.longPressGR];
  self.fetchedResultsController.delegate = nil;
  self.fetchedResultsController = nil;
  
}

#pragma mark - NSFetchedResultsControllerDelegate 
- (void) controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
  
  NSMutableDictionary *change = [NSMutableDictionary dictionary];
  
  switch (type) {
	case NSFetchedResultsChangeInsert: {
	  change[@(type)] = [newIndexPath copy];
	  break;
	}
	case NSFetchedResultsChangeUpdate: {
	  change[@(type)] = [indexPath copy];
	  break;
	}
	case NSFetchedResultsChangeDelete: {
	  change[@(type)] = [indexPath copy];
	  break;
	}
	case NSFetchedResultsChangeMove:
	default:
	  break;
  }
  
  [self.objectsChanged addObject:change];
  
}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {

  if (! (self.isViewLoaded && self.view.window) ) {// view is not appear, stop updating collection view
	[self.objectsChanged removeAllObjects];
	return;
  }
  
  if (self.objectsChanged.count) {
	
	__weak WATimelineViewController *wSelf = self;
	[self.collectionView performBatchUpdates:^{
	  
	  for (NSMutableDictionary *change in wSelf.objectsChanged) {
		
		[change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSIndexPath *idxPath, BOOL *stop) {
		  
		  NSFetchedResultsChangeType type = [key unsignedIntegerValue];
		  switch (type) {
			case NSFetchedResultsChangeInsert:
			  [wSelf.collectionView insertItemsAtIndexPaths:@[idxPath]];
			  break;
			  
			case NSFetchedResultsChangeDelete:
			  [wSelf.collectionView deleteItemsAtIndexPaths:@[idxPath]];
			  break;
			  
			case NSFetchedResultsChangeUpdate:
			  [wSelf.collectionView reloadItemsAtIndexPaths:@[idxPath]];
			  break;
			  
			default:
			  break;
		  }
		  
		}];
		
	  }
	  
	} completion:^(BOOL finished) {
	  
	
	}];
	
	[self.objectsChanged removeAllObjects];
	
  }
}

#pragma mark - UICollectionView datasource

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {

	return 1;

}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

  id <NSFetchedResultsSectionInfo> sectioInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
  return [sectioInfo numberOfObjects];
	
}

- (UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	NSString *identifier = [NSMutableString stringWithString:@"PostCell-"];
	
	switch (post.files.count) {
		case 0:
			identifier = [identifier stringByAppendingString:@"Checkin"];
			break;
		case 1:
			identifier = [identifier stringByAppendingString:@"Photo-1"];
			break;
		case 2:
			identifier = [identifier stringByAppendingString:@"Photo-2"];
			break;
		default:
			identifier = [identifier stringByAppendingString:@"Photo-3"];
	}
		
	WATimelineViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
	
	[cell setRepresentedArticle:post];
	
	return cell;
	
}


#pragma mark - UICollectionViewFlowLayout datasource


- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {

	CGFloat width = CGRectGetWidth(collectionView.frame);
	CGFloat spacing = rowSpacing(collectionView);
	return CGSizeMake(width - spacing * 2, 50);
	
}

- (UICollectionReusableView *) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	
	if (![kind isEqualToString:UICollectionElementKindSectionHeader])
		return nil;
	WADayHeaderView *headerView = (WADayHeaderView*)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"WADayHeaderView" forIndexPath:indexPath];
	
	CGFloat spacing = rowSpacing(collectionView);
	CGRect newFrame = headerView.placeHolderView.frame;
	newFrame.size.width = collectionView.frame.size.width - spacing * 2;
	newFrame.origin.x = spacing;
	headerView.placeHolderView.frame = newFrame;
	
	headerView.dayLabel.text = [self.currentDisplayedDate dayString];
	headerView.monthLabel.text = [[self.currentDisplayedDate localizedMonthShortString] uppercaseString];
	headerView.wdayLabel.text = [[self.currentDisplayedDate localizedWeekDayFullString] uppercaseString];
  [headerView.centerButton addTarget:self action:@selector(calButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	headerView.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];

	[headerView setNeedsLayout];
	return headerView;

}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {

	if (isPad())
		return rowSpacing(collectionView);
	else
		return 0;
	
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {

	if (isPad())
		return 10.0f;
	else
		return 5.0f;
	
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {

	if (isPad()) {
		CGFloat spacing = rowSpacing(collectionView);
		return UIEdgeInsetsMake(5, spacing, 0, spacing);
	} else {
		return UIEdgeInsetsMake(0, 0, 5, 0);
	}
}

#pragma mark - UICollectionView delegate

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	
	WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
  NSURL *aPostURL = [[post objectID] URIRepresentation];
	WAEventViewController *eVC = [WAEventViewController controllerForArticleURL:aPostURL];
		
	WATimelineViewCell *cell = (WATimelineViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
	UIColor *origColor = cell.backgroundColor;
	
	cell.backgroundColor = [UIColor lightGrayColor];
	
	if (isPad()) {
		UINavigationController *navC = [self wrappingNavigationControllerForContextViewController:eVC];
	
		navC.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentViewController:navC animated:YES completion:^{
			cell.backgroundColor = origColor;
		}];
		
	} else {
		
		eVC.completion = ^{
			cell.backgroundColor = origColor;
		};
		[self.navigationController pushViewController:eVC
																				 animated:YES];
		
	}

	[collectionView deselectItemAtIndexPath:indexPath animated:NO];
}

- (UINavigationController *) wrappingNavigationControllerForContextViewController:(WAEventViewController *)controller {
	
	WANavigationController *returnedNavC = nil;
		
	returnedNavC = [[WANavigationController alloc] initWithRootViewController:controller];
		
	if ([returnedNavC isViewLoaded])
		if (returnedNavC.onViewDidLoad)
			returnedNavC.onViewDidLoad(returnedNavC);
	
	return returnedNavC;
	
}

#pragma mark - handle long pressed gesture
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

- (void) calButtonPressed:(id)sender {
  
  if (isPad()) {
	
	CGRect frame = CGRectMake(0, 0, 320, 500);
	
	__weak WATimelineViewController *wSelf = self;
	WACalendarPickerViewController *calVC = [[WACalendarPickerViewController alloc] initWithFrame:frame selectedDate:self.currentDisplayedDate];
	calVC.currentViewStyle = WAEventsViewStyle;
	WANavigationController *wrappedNavVC = [WACalendarPickerViewController wrappedNavigationControllerForViewController:calVC forStyle:WACalendarPickerStyleWithCancel];
	
	UIPopoverController *popOver = [[UIPopoverController alloc] initWithContentViewController:wrappedNavVC];
	[popOver presentPopoverFromRect:CGRectMake(self.collectionView.frame.size.width/2, 50, 1, 1) inView:self.collectionView permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
	self.calendarPopoverForIPad = popOver;
	self.calendarPopoverForIPad.delegate = self;
	calVC.onDismissBlock = ^{
	  [wSelf.calendarPopoverForIPad dismissPopoverAnimated:YES];
	  wSelf.calendarPopoverForIPad = nil;
	};
	
  } else {
	
	CGRect frame = self.view.frame;
	frame.origin = CGPointMake(0, 0);
	__block WACalendarPickerViewController *calVC = [[WACalendarPickerViewController alloc] initWithFrame:frame selectedDate:self.currentDisplayedDate];
	calVC.currentViewStyle = WAEventsViewStyle;
	calVC.onDismissBlock = [^{
	  [calVC.navigationController dismissViewControllerAnimated:YES completion:nil];
	  calVC = nil;
	} copy];
	WANavigationController *wrappedNavVC = [WACalendarPickerViewController wrappedNavigationControllerForViewController:calVC forStyle:WACalendarPickerStyleWithCancel];
	
	wrappedNavVC.modalPresentationStyle = UIModalPresentationFullScreen;
	wrappedNavVC.modalTransitionStyle =  UIModalTransitionStyleCoverVertical;
	[self presentViewController:wrappedNavVC animated:YES completion:nil];
	
  }
  
}


-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {

  self.calendarPopoverForIPad = nil;
  
}

- (void) handleMenu:(UILongPressGestureRecognizer *)longPress {
	
	UIMenuController * const menuController = [UIMenuController sharedMenuController];
	if (menuController.menuVisible)
		return;
	
	BOOL didBecomeFirstResponder = [self becomeFirstResponder];
	NSAssert1(didBecomeFirstResponder, @"%s must require cell to become first responder", __PRETTY_FUNCTION__);
	
	NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[longPress locationInView:self.collectionView]];
	WAArticle *article = [self.fetchedResultsController objectAtIndexPath:indexPath];
	
	WATimelineViewCell *cell = (WATimelineViewCell*) [self.collectionView cellForItemAtIndexPath:indexPath];
	NSParameterAssert(cell.representedArticle == article);	//	Bleh
	
	if (![cell isSelected])
		[self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
	
	menuController.arrowDirection = UIMenuControllerArrowDown;
	
	NSMutableArray *menuItems = [NSMutableArray array];
	
#if TARGET_IPHONE_SIMULATOR
	
	[menuItems addObject:[[UIMenuItem alloc] initWithTitle:@"Make Dirty" action:@selector(makeDirty:)]];
	
#endif
	
	/*
	[menuItems addObject:[[UIMenuItem alloc] initWithTitle:([article.favorite isEqual:(id)kCFBooleanTrue] ?
																													NSLocalizedString(@"ACTION_UNMARK_FAVORITE", @"Action marking article as not favorite") :
																													NSLocalizedString(@"ACTION_MARK_FAVORITE", @"Action marking article as favorite")) action:@selector(toggleFavorite:)]];
	*/
	[menuItems addObject:[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"ACTION_DELETE", @"Action deleting an article") action:@selector(removeArticle:)]];
	
	if ([cell.representedArticle.files count] > 1)
		[menuItems addObject:[[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"ACTION_CHANGE_REPRESENTING_FILE", @"Action changing representing file of an article") action:@selector(editCoverImage:)]];
	
	[menuController setMenuItems:menuItems];
	[menuController update];
	
	CGRect onScreenCellBounds = CGRectIntersection(cell.bounds, [self.collectionView convertRect:self.collectionView.bounds toView:cell]);
	
	[menuController setTargetRect:IRGravitize(onScreenCellBounds, (CGSize){ 8, 8}, kCAGravityCenter) inView:cell];
	[menuController setMenuVisible:YES animated:NO];
	
}

- (void) handleMenuWillHide:(NSNotification *)note {
	
	NSArray *selectedRowIndexPathes = [self.collectionView indexPathsForSelectedItems];
	
	__weak WATimelineViewController *wSelf = self;
	if (selectedRowIndexPathes && selectedRowIndexPathes.count > 0)
		[selectedRowIndexPathes enumerateObjectsUsingBlock:^(NSIndexPath *idxPath, NSUInteger idx, BOOL *stop) {
			[wSelf.collectionView deselectItemAtIndexPath:idxPath animated:YES];
		}];
	
}

- (void) toggleFavorite:(id)sender {
	
	NSArray *selectedIndexPathes = [self.collectionView indexPathsForSelectedItems];
	WAArticle *article = [self.fetchedResultsController objectAtIndexPath:selectedIndexPathes[0]];
	
	NSAssert1(selectedIndexPathes && (selectedIndexPathes.count > 0) && article, @"Selected index path %@ and underlying object must exist", selectedIndexPathes);
	
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
	
	NSArray *selectedIndexPathes = [self.collectionView indexPathsForSelectedItems];
	WAArticle *article = [self.fetchedResultsController objectAtIndexPath:selectedIndexPathes[0]];
	
	if (!selectedIndexPathes || selectedIndexPathes.count == 0 || !article)
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
	
	NSArray *selectedIndexPathes = [self.collectionView indexPathsForSelectedItems];
	WAArticle *article = [self.fetchedResultsController objectAtIndexPath:selectedIndexPathes[0]];
	
	NSAssert1(selectedIndexPathes && (selectedIndexPathes.count > 0) && article, @"Selected index path %@ and underlying object must exist", selectedIndexPathes);
	
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
	
	NSArray *selectedIndexPathes = [self.collectionView indexPathsForSelectedItems];
	WAArticle *article = [self.fetchedResultsController objectAtIndexPath:selectedIndexPathes[0]];
	
	NSAssert1(selectedIndexPathes && (selectedIndexPathes.count > 0) && article, @"Selected index path %@ and underlying object must exist", selectedIndexPathes);
	
	article.dirty = (id)kCFBooleanTrue;
	[article.managedObjectContext save:nil];
	
}



@end
