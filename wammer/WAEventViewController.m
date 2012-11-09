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
#import "WAArticle.h"
#import "WATag.h"
#import "WATagGroup.h"
#import "WALocation.h"
#import "WAPeople.h"
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

+ (NSDateFormatter *) dateFormatter {
	static NSDateFormatter *formatter = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
    formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"EEEE, MMMM d, yyyy"];

	});
	
	return formatter;
}

+ (NSDateFormatter *) timeFormatter {
	static NSDateFormatter *formatter = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
    formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"h:mm a"];
		
	});
	
	return formatter;
}

+ (NSAttributedString *) attributedDescriptionStringForEvent:(WAArticle*)event {

	NSMutableArray *locations = [NSMutableArray array];
	if (event.location != nil && event.location.name != nil) {
		[locations addObject:event.location.name];
	}
	
	NSMutableArray *people = [NSMutableArray array];
	if (event.people != nil) {
		[event.people enumerateObjectsUsingBlock:^(WAPeople *aPersonRep, BOOL *stop) {
			[people addObject:aPersonRep.name];
		}];
	}
	
	NSMutableArray *otherDesc = [NSMutableArray array];
	if (event.descriptiveTags != nil) {
		[event.descriptiveTags enumerateObjectsUsingBlock:^(WATagGroup *aTGRep, BOOL *stop) {
			NSString *leading = aTGRep.leadingString;
			if (aTGRep.tags != nil) {
				NSMutableArray *tags = [NSMutableArray array];
				[[aTGRep.tags allObjects] enumerateObjectsUsingBlock:^(WATag *aTagRep, NSUInteger idx, BOOL *stop) {
					[tags addObject:aTagRep.tagValue];
				}];
				
				if (tags.count) {
					NSString *allTag = [tags componentsJoinedByString:@", "];
					
					[otherDesc addObject:[NSString stringWithFormat:@"%@  %@", leading, allTag]];
				}
			}
		}];
	}
	
	UIFont *hlFont = [UIFont fontWithName:@"Georgia-BoldItalic" size:17.0f];
	
	NSString *locString = [locations componentsJoinedByString:@","];
	NSString *peoString = [people componentsJoinedByString:@","];
	NSString *otherString = [otherDesc componentsJoinedByString:@", "];
	NSMutableString *rawString = nil;
	
	if (event.eventDescription && event.eventDescription.length) {
		rawString = [NSMutableString stringWithFormat:@"%@", event.eventDescription];
	} else {
		rawString = [NSMutableString string];
	}
	
	if (locations && locations.count) {
		[rawString appendFormat:@" at %@", locString];
	}
	
	if (people && people.count) {
		[rawString appendFormat:@" with %@", peoString];
	}
	
	if (otherDesc && otherDesc.count) {
		[rawString appendString:otherString];
	}
		
	NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:rawString];

	UIColor *actionColor = [UIColor colorWithRed:0.96f green:0.64f blue:0.12f alpha:1];
	UIColor *othersColor = [UIColor colorWithRed:0.5f green:0.85 blue:0.96 alpha:1];
	UIColor *locationColor = [UIColor colorWithRed:0.5f green:0.85 blue:0.96 alpha:1];
	UIColor *peopleColor = [UIColor colorWithRed:0.68f green:0.78f blue:0.26f alpha:1];
	
	NSDictionary *actionAttr = [[NSDictionary alloc] initWithObjectsAndKeys:actionColor, NSForegroundColorAttributeName, hlFont, NSFontAttributeName ,nil];
	NSDictionary *othersAttr = [[NSDictionary alloc] initWithObjectsAndKeys:othersColor, NSForegroundColorAttributeName, hlFont, NSFontAttributeName, nil];
	NSDictionary *locationAttr = [[NSDictionary alloc] initWithObjectsAndKeys:locationColor, NSForegroundColorAttributeName, hlFont, NSFontAttributeName, nil];
	NSDictionary *peopleAttr = [[NSDictionary alloc] initWithObjectsAndKeys:peopleColor, NSForegroundColorAttributeName, hlFont, NSFontAttributeName, nil];

	if (event.eventDescription && event.eventDescription.length > 0)
		[attrString setAttributes:actionAttr range:(NSRange){0, event.eventDescription.length}];
	if (locString && locString.length > 0 )
		[attrString setAttributes:locationAttr range:(NSRange)[rawString rangeOfString:locString]];
	if (peoString && peoString.length > 0 )
		[attrString setAttributes:peopleAttr range:(NSRange)[rawString rangeOfString:peoString]];
	if (otherString && otherString.length > 0 )
		[attrString setAttributes:othersAttr range:(NSRange)[rawString rangeOfString:otherString]];
	
	return attrString;
	
}

+ (NSAttributedString *) attributedStringForTags:(NSArray *)tags {
		
	UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:14.0];
	UIColor *bgColor = [UIColor colorWithRed:0.75f green:0.75f blue:0.75f alpha:1];
	UIColor *fgColor = [UIColor whiteColor];
	
	NSDictionary *attr = [[NSDictionary alloc] initWithObjectsAndKeys:fgColor, NSForegroundColorAttributeName, bgColor, NSBackgroundColorAttributeName ,font, NSFontAttributeName, nil];
	
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
	
	if (self.article.location.latitude && self.article.location.longitude) {
		
		CLLocationCoordinate2D center = { self.article.location.latitude.floatValue, self.article.location.longitude.floatValue };
		MKCoordinateSpan span = {0.005, 0.005}; // FIXME: should based on api, currently it is hard coded
		
		[_headerView.mapView setRegion:(MKCoordinateRegion) {center, span}];
		
	} else {
		
		// FIXME: hide the map
		
	}
	
	_headerView.dateLabel.text = [[[self class] dateFormatter] stringFromDate:self.article.creationDate];

	_headerView.timeLabel.text = [[[self class] timeFormatter] stringFromDate:self.article.creationDate];
	
	_headerView.descriptiveTagsLabel.attributedText = [[self class] attributedDescriptionStringForEvent:self.article];
	
	NSMutableArray *tags = [NSMutableArray array];
	[[self.article.tags allObjects] enumerateObjectsUsingBlock:^(WATag  *aTagRep, NSUInteger idx, BOOL *stop) {
		[tags addObject:aTagRep.tagValue];
	}];
	_headerView.tagsLabel.attributedText = [[self class]attributedStringForTags:tags];
		
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
