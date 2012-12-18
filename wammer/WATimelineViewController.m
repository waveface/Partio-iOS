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

@interface WATimelineViewController () <NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowlayout;

@property (nonatomic, strong) NSDate *currentDisplayedDate;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, readwrite, retain) UILongPressGestureRecognizer *longPressGR;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) UIButton *calendarButton;

@end

@implementation WATimelineViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (!self)
			return nil;

	self.flowlayout = [[UICollectionViewFlowLayout alloc] init];
	self.flowlayout.itemSize = (CGSize) {320, 310};
	self.flowlayout.scrollDirection = UICollectionViewScrollDirectionVertical;

	CGRect rect = (CGRect) { CGPointZero, self.view.frame.size };
	self.collectionView = [[UICollectionView alloc] initWithFrame:rect collectionViewLayout:self.flowlayout];
 
	self.collectionView.dataSource = self;
	self.collectionView.delegate = self;
	self.collectionView.autoresizesSubviews = YES;
 
	self.collectionView.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];

	[self.collectionView registerNib:[UINib nibWithNibName:@"WADayHeaderView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"WADayHeaderView"];
	[self.collectionView registerNib:[UINib nibWithNibName:@"WATimelineViewCell-ImageStack-1" bundle:nil] forCellWithReuseIdentifier:@"PostCell-Photo-1"];
	[self.collectionView registerNib:[UINib nibWithNibName:@"WATimelineViewCell-ImageStack-2" bundle:nil] forCellWithReuseIdentifier:@"PostCell-Photo-2"];
	[self.collectionView registerNib:[UINib nibWithNibName:@"WATimelineViewCell-ImageStack-3" bundle:nil] forCellWithReuseIdentifier:@"PostCell-Photo-3"];
	[self.collectionView registerNib:[UINib nibWithNibName:@"WATimelineViewCell-Checkin" bundle:nil] forCellWithReuseIdentifier:@"PostCell-Checkin"];

	self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:self.collectionView];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	self.longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenu:)];
	[self.collectionView addGestureRecognizer:self.longPressGR];

	return self;
}

- (id) initWithDate:(NSDate*)date {
	
	self.currentDisplayedDate = [date copy];
	[self fetchedResultsController];
	
	return [self initWithNibName:nil bundle:nil];
	
}

- (void) viewWillAppear:(BOOL)animated {
	
	[self.collectionView.collectionViewLayout invalidateLayout];
	
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

#pragma mark - MOC and NSFetchResultsController
- (NSManagedObjectContext *) managedObjectContext {
	
	if (_managedObjectContext)
		return _managedObjectContext;
	
	_managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
	
	return _managedObjectContext;
	
}

- (NSFetchedResultsController *) fetchedResultsController {
	
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
	
  NSError *fetchingError;
	if (![_fetchedResultsController performFetch:&fetchingError])
		NSLog(@"error fetching: %@", fetchingError);
	
	return _fetchedResultsController;
	
}

#pragma mark - UICollectionView datasource

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {

	return 1;

}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

	return [(id<NSFetchedResultsSectionInfo>)[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
	
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

CGFloat (^rowSpacing) (UICollectionView *) = ^ (UICollectionView *collectionView) {
	
	CGFloat width = CGRectGetWidth(collectionView.frame);
	CGFloat itemWidth = ((UICollectionViewFlowLayout*)collectionView.collectionViewLayout).itemSize.width;
	int numCell = (int)(width / itemWidth);
	
	CGFloat w = ((int)((int)(width) % (int)(itemWidth))) / (numCell + 1);

	return w;
};

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {

	CGFloat width = CGRectGetWidth(collectionView.frame);
	CGFloat spacing = rowSpacing(collectionView);
	return CGSizeMake(width - spacing * 2, 44);
	
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
	headerView.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];

	[headerView.centerButton addTarget:self action:@selector(handleDateSelect:) forControlEvents:UIControlEventTouchUpInside];
	self.calendarButton = headerView.centerButton;
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

#pragma mark - Calendar

- (void) handleDateSelect:(UIBarButtonItem *)sender {
	
	CGRect frame = isPad()? CGRectMake(0.f, 0.f, 320.f, 568.f) : CGRectMake(0.f, 0.f, 320.f, [UIScreen mainScreen].bounds.size.height);
	
	if (isPad()) {
		if ([self.popover isPopoverVisible]) {
				[self.popover dismissPopoverAnimated:YES];
		
		} else {
			WACalendarPickerViewController *dpVC = [[WACalendarPickerViewController alloc] initWithFrame:frame style:WACalendarPickerStyleInPopover];
			dpVC.delegate = self;
			
			self.popover = [[UIPopoverController alloc] initWithContentViewController:dpVC];
			[self.popover setPopoverContentSize:CGSizeMake(320.f, 568.f)];
			[self.popover presentPopoverFromRect:self.calendarButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
		}
		
	} else {
		WACalendarPickerViewController *dpVC = [[WACalendarPickerViewController alloc] initWithFrame:frame style:WACalendarPickerStyleTodayCancel];
		dpVC.delegate = self;
		
		[self presentViewController:dpVC animated:YES completion:nil];
	
	}
}

#pragma mark - UICollectionView delegate

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	
	WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
	WAEventViewController *eVC = [WAEventViewController controllerForArticle:post];
		
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
