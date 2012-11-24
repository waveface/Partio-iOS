//
//  WATimelineViewControllerPadViewController.m
//  wammer
//
//  Created by Shen Steven on 11/20/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WATimelineViewControllerPad.h"
#import "WARemoteInterface.h"
#import "WADataStore.h"
#import "WAPostViewCellPad.h"
#import "WADayHeaderView.h"
#import "NSDate+WAAdditions.h"
#import "WAEventViewController.h"
#import "WANavigationController.h"
#import "WAAppearance.h"

@interface WATimelineViewControllerPad () <NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowlayout;

@property (nonatomic, strong) NSDate *currentDisplayedDate;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation WATimelineViewControllerPad

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
	[self.collectionView registerNib:[UINib nibWithNibName:@"WAPostViewCellPad-ImageStack-1" bundle:nil] forCellWithReuseIdentifier:@"PostCell-Photo-1"];
	[self.collectionView registerNib:[UINib nibWithNibName:@"WAPostViewCellPad-ImageStack-2" bundle:nil] forCellWithReuseIdentifier:@"PostCell-Photo-2"];
	[self.collectionView registerNib:[UINib nibWithNibName:@"WAPostViewCellPad-ImageStack-3" bundle:nil] forCellWithReuseIdentifier:@"PostCell-Photo-3"];

	self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:self.collectionView];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

	return self;
}

- (id) initWithDate:(NSDate*)date {
	
	self.currentDisplayedDate = [date copy];
	[self fetchedResultsController];
	
	return [self initWithNibName:nil bundle:nil];
	
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
	
	NSString *identifier = [NSMutableString stringWithString:@"PostCell-Photo"];

	NSAssert(post.files.count > 0, @"Event post needs more then one photo");
	
	if (post.files.count == 1)
		identifier = [identifier stringByAppendingString:@"-1"];
	else if (post.files.count == 2)
		identifier = [identifier stringByAppendingString:@"-2"];
	else
		identifier = [identifier stringByAppendingString:@"-3"];
		
	WAPostViewCellPad *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
	
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

	[headerView setNeedsLayout];
	return headerView;

}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {

	return rowSpacing(collectionView);
	
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {

	return 10.0f;
	
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
	
	CGFloat spacing = rowSpacing(collectionView);
	
	return UIEdgeInsetsMake(5, spacing, 0, spacing);

}

#pragma mark - UICollectionView delegate

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	
	WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
	WAEventViewController *eVC = [WAEventViewController controllerForArticle:post];
	
	UINavigationController *navC = [self wrappingNavigationControllerForContextViewController:eVC];
	
	navC.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentViewController:navC animated:YES completion:nil];
		
}

- (UINavigationController *) wrappingNavigationControllerForContextViewController:(WAEventViewController *)controller {
	
	WANavigationController *returnedNavC = nil;
		
	returnedNavC = [[WANavigationController alloc] initWithRootViewController:controller];
		
	if ([returnedNavC isViewLoaded])
		if (returnedNavC.onViewDidLoad)
			returnedNavC.onViewDidLoad(returnedNavC);
	
	return returnedNavC;
	
}

@end
