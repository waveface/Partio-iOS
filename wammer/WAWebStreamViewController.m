//
//  WAWebStreamViewController.m
//  wammer
//
//  Created by Shen Steven on 12/17/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAWebStreamViewController.h"
#import "WAWebStreamViewCell.h"
#import "WADayHeaderView.h"
#import "NSDate+WAAdditions.h"
#import "WADataStore.h"

@interface WAWebStreamViewController () <NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, readwrite, strong) NSDate *currentDate;
@property (nonatomic, readwrite, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, strong) UICollectionView *collectionView;

@end

@implementation WAWebStreamViewController

- (id)initWithDate:(NSDate *)date {
	
	self = [super init];
	if (self) {
		
		self.currentDate = date;
		
		NSManagedObjectContext *context = [[WADataStore defaultStore] autoUpdatingMOC];
		
		NSFetchRequest *fr = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"WAFile" inManagedObjectContext:context];
		[fr setEntity:entity];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"created BETWEEN {%@, %@} AND type == 'web'", [self.currentDate dayBegin], [self.currentDate dayEnd]];
		[fr setPredicate:predicate];
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"created" ascending:YES];
		[fr setSortDescriptors:@[sortDescriptor]];
		
		self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
		self.fetchedResultsController.delegate = self;
		
		NSError *fetchingError;
		if (![self.fetchedResultsController performFetch:&fetchingError])
			NSLog(@"error fetching: %@", fetchingError);

	}
	
	return self;
	
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	UICollectionViewFlowLayout *flowlayout = [[UICollectionViewFlowLayout alloc] init];
	flowlayout.itemSize = (CGSize) {320, 310};
	flowlayout.scrollDirection = UICollectionViewScrollDirectionVertical;

	CGRect rect = (CGRect) { CGPointZero, self.view.frame.size };
	self.collectionView = [[UICollectionView alloc] initWithFrame:rect collectionViewLayout:flowlayout];
	
	self.collectionView.dataSource = self;
	self.collectionView.delegate = self;
	self.collectionView.autoresizesSubviews = YES;
	
	self.collectionView.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];
	self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:self.collectionView];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	
	[self.collectionView registerNib:[UINib nibWithNibName:@"WAWebStreamViewCell" bundle:nil] forCellWithReuseIdentifier:@"WAWebStreamViewCell"];
	[self.collectionView registerNib:[UINib nibWithNibName:@"WADayHeaderView" bundle:nil] forCellWithReuseIdentifier:@""];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger) supportedInterfaceOrientations {
	
	if (isPad()) {
		
		return UIInterfaceOrientationMaskAll;
		
	} else {
		
		return UIInterfaceOrientationMaskPortrait;
		
	}
	
}

- (BOOL) shouldAutorotate {
	
	return YES;
	
}

#pragma mark - UICollectionView DataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {

	return 1;

}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	
	return [self.fetchedResultsController.sections[0] numberOfObjects];
	
}

- (UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	WAFile *file = [self.fetchedResultsController objectAtIndexPath:indexPath];
	if (!file)
		return nil;
	
	WAWebStreamViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WAWebStreamViewCell" forIndexPath:indexPath];
	
	cell.webTitleLabel.text = file.webTitle;
	cell.webURLLabel.text = file.webURL;

	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"hh:mm"];

	cell.dateTimeLabel.text = [formatter stringFromDate:file.created];
	
	return cell;
	
}

CGFloat (^rowSpacingWeb) (UICollectionView *) = ^ (UICollectionView *collectionView) {
	
	CGFloat width = CGRectGetWidth(collectionView.frame);
	CGFloat itemWidth = ((UICollectionViewFlowLayout*)collectionView.collectionViewLayout).itemSize.width;
	int numCell = (int)(width / itemWidth);
	
	CGFloat w = ((int)((int)(width) % (int)(itemWidth))) / (numCell + 1);
	
	return w;
};

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
	
	CGFloat width = CGRectGetWidth(collectionView.frame);
	CGFloat spacing = rowSpacingWeb(collectionView);
	return CGSizeMake(width - spacing * 2, 50);
	
}

- (UICollectionReusableView *) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	
	if (![kind isEqualToString:UICollectionElementKindSectionHeader])
		return nil;
	WADayHeaderView *headerView = (WADayHeaderView*)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"WADayHeaderView" forIndexPath:indexPath];
	
	CGFloat spacing = rowSpacingWeb(collectionView);
	CGRect newFrame = headerView.placeHolderView.frame;
	newFrame.size.width = collectionView.frame.size.width - spacing * 2;
	newFrame.origin.x = spacing;
	headerView.placeHolderView.frame = newFrame;
	
	headerView.dayLabel.text = [self.currentDate dayString];
	headerView.monthLabel.text = [[self.currentDate localizedMonthShortString] uppercaseString];
	headerView.wdayLabel.text = [[self.currentDate localizedWeekDayFullString] uppercaseString];
	headerView.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];
	
//	[headerView.centerButton addTarget:self action:@selector(handleDateSelect:) forControlEvents:UIControlEventTouchUpInside];
	[headerView setNeedsLayout];
	return headerView;
	
}


#pragma mark - UICollectionView Delegate
-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	
}

@end
