//
//  WAEventViewController.m
//  wammer
//
//  Created by Shen Steven on 11/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAEventViewController.h"
#import "WADataStore.h"
#import "WADataStore+FetchingConveniences.h"
#import "IRBarButtonItem.h"
#import "WAAppearance.h"
#import "WAEventPhotoViewCell.h"

@interface WAEventViewController ()

@property (nonatomic, strong, readwrite) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong, readwrite) UICollectionView *itemsView;
@property (nonatomic, strong) WAEventHeaderView *headerView;

@end

@implementation WAEventViewController

+ (WAEventViewController *) controllerForArticle:(WAArticle *)article {
	
	NSMutableString *literal = [[NSMutableString alloc] initWithString:@"WAEventViewController"];
	
	if ([article.style isEqualToNumber:[NSNumber numberWithInteger:WAPostStyleURLHistory]]) {
		[literal appendString:@"_Link"]; // FIXME
	} else {
		[literal appendString:@"_Photo"];
	}
	
	Class class = NSClassFromString(literal);
	if (!class)
		class = [self class];

	WAEventViewController *eventVC = [[class alloc] init];
	eventVC.article = article;
	
	return eventVC;
	
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
	
	[super viewDidLoad];
	
		
	CGRect rect = (CGRect){ CGPointZero, self.view.frame.size };
	rect.size.height -= CGRectGetHeight(self.navigationController.navigationBar.frame);
	
	UICollectionViewFlowLayout *flowlayout = [[UICollectionViewFlowLayout alloc] init];
	flowlayout.scrollDirection = UICollectionViewScrollDirectionVertical;
	flowlayout.sectionInset = UIEdgeInsetsMake(0, 5.0f, 5.0f, 5.0f);
	self.itemsView = [[UICollectionView alloc] initWithFrame:rect
																		 collectionViewLayout:flowlayout];
	self.itemsView.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];
	self.itemsView.bounces = YES;
	self.itemsView.alwaysBounceVertical = YES;
	self.itemsView.alwaysBounceHorizontal = NO;
	self.itemsView.allowsSelection = YES;
	self.itemsView.allowsMultipleSelection = NO;

	self.itemsView.dataSource = self;
	self.itemsView.delegate = self;
	
	[self.view addSubview:self.itemsView];

	__weak WAEventViewController *wSelf = self;
	self.navigationItem.leftBarButtonItem = WABackBarButtonItem([UIImage imageNamed:@"back"], @"", ^{
		[wSelf.navigationController popViewControllerAnimated:YES];
	});

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSFetchedResultsController *) fetchedResultsController {
	
	if (_fetchedResultsController)
		return _fetchedResultsController;
	
	NSFetchRequest *fetchRequest = [[WADataStore defaultStore] newFetchRequestForFilesInArticle:self.article];
	
	_fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.article.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	_fetchedResultsController.delegate = self;
	
	NSError *fetchError = nil;
	if (![_fetchedResultsController performFetch:&fetchError])
		NSLog(@"Error fetching: %@", fetchError);
	
	return _fetchedResultsController;
	
}

+ (NSDateFormatter *) dateFormatterForTopLabel {
	static NSDateFormatter *formatter = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
    formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"EEEE | h:mm a"];

	});
	
	return formatter;
}

- (NSAttributedString *) attributedStringForEventDescription {
	
	NSString *action = @"Take Picture";
	NSArray *locations = @[@"Baker Street", @"London"];
	NSArray *people = @[@"Steven Shen"];
	
	NSString *locString = [locations componentsJoinedByString:@","];
	NSString *peoString = [people componentsJoinedByString:@","];
	NSString *rawString = [NSString stringWithFormat:@"%@ At %@ with %@", action, locString, peoString];
	
	NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:rawString];

	UIColor *actionColor = [UIColor orangeColor];
	UIColor *keywordsColor = [UIColor blueColor];
	UIColor *locationColor = [UIColor blueColor];
	UIColor *peopleColor = [UIColor greenColor];
	
	NSDictionary *actionAttr = [[NSDictionary alloc] initWithObjectsAndKeys:actionColor, NSForegroundColorAttributeName, nil];
	NSDictionary *keywordsAttr = [[NSDictionary alloc] initWithObjectsAndKeys:keywordsColor, NSForegroundColorAttributeName, nil];
	NSDictionary *locationAttr = [[NSDictionary alloc] initWithObjectsAndKeys:locationColor, NSForegroundColorAttributeName, nil];
	NSDictionary *peopleAttr = [[NSDictionary alloc] initWithObjectsAndKeys:peopleColor, NSForegroundColorAttributeName, nil];

	if (action && action.length > 0)
		[attrString setAttributes:actionAttr range:(NSRange){0, action.length}];
	if (locString && locString.length > 0 )
		[attrString setAttributes:locationAttr range:(NSRange)[rawString rangeOfString:locString]];
	if (peoString && peoString.length > 0 )
		[attrString setAttributes:peopleAttr range:(NSRange)[rawString rangeOfString:peoString]];
	
	return attrString;
	
}

- (NSAttributedString *) attributedStringForTags {
	
	NSArray *tags = @[@"Google", @"Yahoo"];
	
	UIColor *bgColor = [UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:1];
	UIColor *fgColor = [UIColor whiteColor];
	
	NSDictionary *attr = [[NSDictionary alloc] initWithObjectsAndKeys:fgColor, NSForegroundColorAttributeName, bgColor, NSBackgroundColorAttributeName ,nil];
	
	NSString *rawString = [tags componentsJoinedByString:@" "];
	NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:rawString];

	for (int i = 0; i < tags.count; i++) {
		[attrString setAttributes:attr range:(NSRange)[rawString rangeOfString:[tags objectAtIndex:i]]];
	}
	
	return attrString;
}

- (WAEventHeaderView *) headerView {
	
	if (_headerView)
		return _headerView;

	_headerView = [WAEventHeaderView viewFromNib];
	
	NSDateFormatter *formatter = [[self class] dateFormatterForTopLabel];
	_headerView.topLabel.text = [formatter stringFromDate:self.article.creationDate];
	
	_headerView.descriptiveTagsLabel.attributedText = [self attributedStringForEventDescription];
	_headerView.tagsLabel.attributedText = [self attributedStringForTags];
		
	return _headerView;

}


#pragma mark - CollectionView datasource
- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	
	return 1;
	
}

- (UICollectionReusableView *) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {

	if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {

		return self.headerView;
		
	}
	
	return nil;
	
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	
	//	return [[self.fetchedResultsController fetchedObjects] count];
	return self.article.files.count;
	
}

- (UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	[NSException raise:NSInternalInconsistencyException format:@"Subclass shall implement %s", __PRETTY_FUNCTION__];

	return nil;
	
}

#pragma mark - UICollectionViewFlowLayout delegate
- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	[NSException raise:NSInternalInconsistencyException format:@"Subclass shall implement %s", __PRETTY_FUNCTION__];
	
	return CGSizeZero;
	
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
	
	[NSException raise:NSInternalInconsistencyException format:@"Subclass shall implement %s", __PRETTY_FUNCTION__];

	return 0.0f;
	
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {

	[NSException raise:NSInternalInconsistencyException format:@"Subclass shall implement %s", __PRETTY_FUNCTION__];

	return 0.0f;
	
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
	
	return self.headerView.frame.size;

}

#pragma mark - CollectionView delegate
- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	
	[NSException raise:NSInternalInconsistencyException format:@"Subclass shall implement %s", __PRETTY_FUNCTION__];

}


@end
