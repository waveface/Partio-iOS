//
//  WAEventViewController.m
//  wammer
//
//  Created by Shen Steven on 11/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAEventViewController.h"

#import "WADataStore.h"
#import "WAArticle.h"
#import "WATag.h"
#import "WATagGroup.h"
#import "WALocation.h"
#import "WAPeople.h"

#import "WAAnnotation.h"
#import "WAEventPhotoViewCell.h"
#import "WAEventPeopleListViewController.h"
#import "WAAppearance.h"

#import "UIKit+IRAdditions.h"
#import "MKMapView+ZoomLevel.h"
#import "NINetworkImageView.h"
#import "GAI.h"
#import "WANavigationController.h"

#import <GoogleMaps/GoogleMaps.h>

#import "WACompositionViewController.h"
#import "WACompositionViewController+CustomUI.h"

@interface WAEventViewController () <MKMapViewDelegate>

@property (nonatomic, strong, readwrite) UICollectionView *itemsView;
@property (nonatomic, strong) WAEventHeaderView *headerView;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation WAEventViewController

+ (WAEventViewController *) controllerForArticleURL:(NSURL*)anArticleURL {
	NSMutableString *literal = [[NSMutableString alloc] initWithString:@"WAEventViewController"];
	
	[literal appendString:@"_Photo"];

	
	Class class = NSClassFromString(literal);
	if (!class)
		class = [self class];

	WAEventViewController *eventVC = [[class alloc] init];
	eventVC.articleURL = anArticleURL;
	
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

- (NSManagedObjectContext *) managedObjectContext {
  
  if (_managedObjectContext)
	return _managedObjectContext;
  
  _managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
  return _managedObjectContext;
}

- (WAArticle *) article {
  
  if (_article)
	return _article;
  
  NSAssert(self.articleURL != nil, @"Must specify an article URL for Event view");
  
  _article = (WAArticle*)[self.managedObjectContext irManagedObjectForURI:self.articleURL];
  [_article addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
  return _article;
  
}

- (void)viewDidLoad
{
	
	[super viewDidLoad];
  		
	CGRect rect = (CGRect){ CGPointZero, self.view.frame.size };
	
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
	self.itemsView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

	self.itemsView.dataSource = self;
	self.itemsView.delegate = self;
	
	[self.view addSubview:self.itemsView];

	__weak WAEventViewController *wSelf = self;
	self.navigationItem.leftBarButtonItem = WABackBarButtonItem([UIImage imageNamed:@"back"], @"", ^{
		
		if (isPad() && wSelf.parentViewController.modalPresentationStyle == UIModalPresentationFormSheet) {

			[wSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
			
		} else {
		  [wSelf.parentViewController dismissViewControllerAnimated:YES completion:nil];
		}
		
	});
	
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if (self.article.location.latitude && self.article.location.longitude) {
		
	  NSUInteger zoomLevel = 15; // hardcoded, but we may tune this in the future
		

      GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:self.article.location.latitude.floatValue
                                                              longitude:self.article.location.longitude.floatValue
                                                                   zoom:zoomLevel];
      
      [_headerView.mapView setCamera:camera];
      _headerView.mapView.myLocationEnabled = NO;
      for (WALocation *loc in self.article.checkins) {   
        GMSMarkerOptions *options = [[GMSMarkerOptions alloc] init];
        CLLocationCoordinate2D checkinCenter = { loc.latitude.floatValue, loc.longitude.floatValue };
        options.position = checkinCenter;
        if (loc.name)
          options.title = loc.name;
        else
          options.title = nil;
        options.icon = [UIImage imageNamed:@"pindrop"];
        [_headerView.mapView addMarkerWithOptions:options];
        
      }
  		
	}
	
	if (self.completion)
		self.completion();

}

- (void)viewWillAppear:(BOOL)animated
{
	CGSize shadowSize = CGSizeMake(15.0, 1.0);
	UIGraphicsBeginImageContext(shadowSize);
	CGContextRef shadowContext = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(shadowContext, [UIColor colorWithRed:193/255.0 green:193/255.0 blue:193/255.0 alpha:1].CGColor);
	CGContextAddRect(shadowContext, CGRectMake(7.0, 0, 1.0, shadowSize.height));
	CGContextFillPath(shadowContext);
	UIImage *naviShadow = UIGraphicsGetImageFromCurrentImageContext();
	static UIImage *naviShadowWithInsets;
	naviShadowWithInsets = [naviShadow resizableImageWithCapInsets:UIEdgeInsetsMake(0, 7, 0, 7)];
	UIGraphicsEndImageContext();
	[self.navigationController.navigationBar setShadowImage:naviShadowWithInsets];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc {
  
  if (_article)
	[_article removeObserver:self forKeyPath:@"text"];
  
}

- (BOOL) shouldAutorotate {

	if (isPad())
		return YES;
	return NO;

}

- (NSUInteger) supportedInterfaceOrientations {

	if (isPad())
		return UIInterfaceOrientationMaskAll;
	return UIInterfaceOrientationMaskPortrait;

}

- (void) tapOutsideHandler:(UITapGestureRecognizer*)sender {
	
	if (self.presentedViewController!=nil)
		return;
	if (sender.state == UIGestureRecognizerStateEnded) {
		
		CGPoint location = [sender locationInView:nil];
		
		if (![self.navigationController.view pointInside:[self.navigationController.view convertPoint:location fromView:self.view.window] withEvent:nil]) {
			
			[self.view.window removeGestureRecognizer:sender];
			[self dismissViewControllerAnimated:YES completion:nil];
			
		}
	}
	
}

+ (NSDateFormatter *) dateFormatter {
	static NSDateFormatter *formatter = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
    formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"EEEE, d MMM"];

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

+ (NSAttributedString *) attributedDescriptionStringForEvent:(WAArticle*)event styleWithColor:(BOOL)colonOn styleWithFontForTableView:(BOOL)fontForTableViewOn {

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
  UIFont *descFont = [UIFont fontWithName:@"Georgia-Bold" size:17.0f];
	UIFont *calFont = [UIFont fontWithName:@"Georgia-Italic" size:14.0f];
	UIFont *calBFont = [UIFont boldSystemFontOfSize:14.f];
	UIColor *calTextColor = [UIColor colorWithRed:0.353f green:0.361f blue:0.361f alpha:1.f];

	NSString *locString = [locations componentsJoinedByString:@","];
	NSString *peoString = [people componentsJoinedByString:@","];
	NSString *otherString = [otherDesc componentsJoinedByString:@", "];
	NSMutableString *rawString = nil;
	
  if (event.text.length) {
	
	rawString = [NSMutableString stringWithFormat:@"%@", event.text];
	
  } else if (event.textAuto && event.textAuto.length) {
	
	rawString = [NSMutableString stringWithFormat:@"%@", event.textAuto];
	
  } else {
	rawString = [NSMutableString string];
  }
	
	if (locations && locations.count) {
	  NSString *locConjunction = NSLocalizedString(@"EVENT_DESC_LOCATION_CONJUNCTION", @"The conjunction between description and location.");
		[rawString appendFormat:@" %@ %@", locConjunction, locString];
	}
	
	if (people && people.count) {
	  NSString *peopleConjunction = NSLocalizedString(@"EVENT_DESC_PEOPLE_CONJUNCTION", @"The conjunction between description and people's names");
	  [rawString appendFormat:@" %@ %@", peopleConjunction, peoString];
	}
	
	if (otherDesc && otherDesc.count) {
		[rawString appendString:otherString];
	}
		
	NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:rawString];

  UIColor *generatedDescColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
	UIColor *actionColor = [UIColor colorWithRed:0.96f green:0.64f blue:0.12f alpha:1];
	UIColor *othersColor = [UIColor colorWithRed:0.5f green:0.85 blue:0.96 alpha:1];
	UIColor *locationColor = [UIColor colorWithRed:0.5f green:0.85 blue:0.96 alpha:1];
	UIColor *peopleColor = [UIColor colorWithRed:0.68f green:0.78f blue:0.26f alpha:1];

  NSDictionary *generatedDescAttr = @{NSForegroundColorAttributeName: colonOn? generatedDescColor : calTextColor, NSFontAttributeName: fontForTableViewOn? calFont : hlFont};
	NSDictionary *actionAttr = @{NSForegroundColorAttributeName: colonOn? actionColor : calTextColor, NSFontAttributeName: fontForTableViewOn? calFont : descFont};
	NSDictionary *locationAttr = @{NSForegroundColorAttributeName: colonOn? locationColor : calTextColor, NSFontAttributeName: fontForTableViewOn? calFont : hlFont};
	NSDictionary *peopleAttr = @{NSForegroundColorAttributeName: colonOn? peopleColor : calTextColor, NSFontAttributeName: fontForTableViewOn? calFont : hlFont};
	NSDictionary *othersAttr = @{NSForegroundColorAttributeName: colonOn? othersColor : calTextColor, NSFontAttributeName: fontForTableViewOn? calBFont : hlFont};
	
	if (attrString.length > 0)
		[attrString setAttributes:othersAttr range:(NSRange)[rawString rangeOfString:rawString]];
  
  if (event.text.length)
	[attrString setAttributes:actionAttr range:(NSRange){0, event.text.length}];
  else if (event.textAuto && event.textAuto.length > 0)
	[attrString setAttributes:generatedDescAttr range:(NSRange){0, event.textAuto.length}];

  if (locString && locString.length > 0 )
	[attrString setAttributes:locationAttr range:(NSRange)[rawString rangeOfString:locString]];
  if (peoString && peoString.length > 0 )
	[attrString setAttributes:peopleAttr range:(NSRange)[rawString rangeOfString:peoString]];

	
	return attrString;
	
}

+ (NSAttributedString *) attributedDescriptionStringForEvent:(WAArticle*)event {
	
	return [[self class] attributedDescriptionStringForEvent:event styleWithColor:YES styleWithFontForTableView:NO];
	
}

+ (NSAttributedString *) attributedStringForTags:(NSArray *)tags {
		
	UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:14.0];
	UIColor *bgColor = [UIColor colorWithRed:0.75f green:0.75f blue:0.75f alpha:1];
	UIColor *fgColor = [UIColor whiteColor];
	
	NSDictionary *attr = [[NSDictionary alloc]
												initWithObjectsAndKeys:fgColor, NSForegroundColorAttributeName,
												bgColor, NSBackgroundColorAttributeName ,
												font, NSFontAttributeName,nil];
	
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

	_headerView.dateLabel.text = [[[self class] dateFormatter] stringFromDate:self.article.eventStartDate];
	
	_headerView.timeLabel.text = [[[self class] timeFormatter] stringFromDate:self.article.eventStartDate];
	
	_headerView.numberLabel.text = [NSString stringWithFormat:NSLocalizedString(@"EVENT_PHOTO_NUMBER_LABEL", @"EVENT_PHOTO_NUMBER_LABEL"), self.article.files.count];
	
	if (self.article.people != nil) {
		
		NSUInteger idx = 0;
		CGRect avatarRect = (CGRect){ {4, 4}, {36, 36}};

		for (WAPeople *aPersonRep in self.article.people) {
			
			NINetworkImageView *avatarImageView = [[NINetworkImageView alloc] initWithFrame:avatarRect];
			[avatarImageView setPathToNetworkImage:aPersonRep.avatarURL contentMode:UIViewContentModeCenter];
			[self.headerView.avatarPlacehoder addSubview:avatarImageView];

			avatarRect.origin.y = avatarRect.origin.y + avatarRect.size.height + 4;

			idx ++;
			if (idx >= 2)
				break;
		}
		
		if (idx == 2 && self.article.people.count > 2) {
			UIButton *more = [UIButton buttonWithType:UIButtonTypeCustom];
			more.frame = avatarRect;
			more.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];
			more.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0];
			more.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
			more.titleLabel.textAlignment = NSTextAlignmentCenter;
			[more setTitle:[NSString stringWithFormat:@"%d More", self.article.people.count - 2] forState:UIControlStateNormal];
			[more addTarget:self action:@selector(showPeopleBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
			[self.headerView.avatarPlacehoder addSubview:more];
		} else {
			
			for (int i = 0; i < (3-idx); i++) {
				UIButton *add = [UIButton buttonWithType:UIButtonTypeCustom];
				
				add.frame = avatarRect;
				NSString *imageName = [NSString stringWithFormat:@"P%d", i+1];
				[add setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
				avatarRect.origin.y = avatarRect.origin.y + avatarRect.size.height + 4;
				[add addTarget:self action:@selector(addMorePeopleBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
				
				[self.headerView.avatarPlacehoder addSubview:add];
				
			}
		}
	}
	
	if (self.article.location && self.article.location.latitude && self.article.location.longitude) {
		
		NSMutableArray *allTags = [NSMutableArray array];

		for (WALocation *loc in self.article.checkins) {
				if (loc.name)
					[allTags addObject:loc.name];
		}
		
		if (allTags.count > 0) // dedup
			allTags = [NSMutableArray arrayWithArray:[[NSSet setWithArray:allTags] allObjects]];
		
		for (WATag *aTagRep in self.article.location.tags) {
			[allTags addObject:aTagRep.tagValue];
		}
				
		if (allTags.count)
			_headerView.locationLabel.text = [NSString stringWithFormat:@"at %@", [allTags componentsJoinedByString:@", "]];
		else
			_headerView.locationLabel.text = NSLocalizedString(@"LABEL_WITHOUT_GPS_DATA", @"The text of location label when there is no gps information we can refer to");
		
	} else {
		
		_headerView.locationMarkImageView.image = [UIImage imageNamed:@"NoLocation"];
		_headerView.locationLabel.text = NSLocalizedString(@"LABEL_WITHOUT_GPS_DATA", @"The text of location label when there is no gps information we can refer to");
		
	}

	_headerView.descriptiveTagsLabel.attributedText = [[self class] attributedDescriptionStringForEvent:self.article];
	[_headerView.descriptiveTagsLabel invalidateIntrinsicContentSize];
  
  [_headerView.descriptionTapper addTarget:self action:@selector(handleChangeDescription:) forControlEvents:UIControlEventTouchUpInside];
	
	NSMutableArray *tags = [NSMutableArray array];
	[[self.article.tags allObjects] enumerateObjectsUsingBlock:^(WATag  *aTagRep, NSUInteger idx, BOOL *stop) {
		[tags addObject:aTagRep.tagValue];
	}];
	
	if (tags.count) {
		
		_headerView.tagsLabel.attributedText = [[self class]attributedStringForTags:tags];
		[_headerView.tagsLabel invalidateIntrinsicContentSize];
		
	} else {

		[_headerView.tagsLabel setHidden:YES];
		
	}
	
	if (!self.article.files.count) {
		
		_headerView.labelOverSeparationLine.text = NSLocalizedString(@"EVENT_SEPERATION_LABEL_WITHOUT_PHOTOS", @"The text of label on separation line in the event view when there is no photo presented.");
		[_headerView.labelOverSeparationLine sizeToFit];
		
	}
	
	CGRect newFrame = _headerView.frame;
	newFrame.size.width = CGRectGetWidth(self.itemsView.frame);
	_headerView.frame = newFrame;
	_headerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
 
	[_headerView setNeedsLayout];
	
	return _headerView;

}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  
  if ([keyPath isEqualToString:@"text"]) {
	
	NSString *newText = [change valueForKey:NSKeyValueChangeNewKey];
	NSString *oldText = [change valueForKey:NSKeyValueChangeOldKey];
	
	if (![newText isEqualToString:oldText]) {
	  _headerView.descriptiveTagsLabel.attributedText = [[self class] attributedDescriptionStringForEvent:self.article];
	}
  }
  
}

#pragma mark - Handle Actions

- (void) showPeopleBtnPressed:(id)sender {

	if (isPhone()) {
		WAEventPeopleListViewController *plVC = [[WAEventPeopleListViewController alloc] initWithStyle:UITableViewStylePlain];
		plVC.peopleList = [self.article.people allObjects];
	
		UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:plVC];
		plVC.navigationItem.leftBarButtonItem = WABarButtonItem(nil, NSLocalizedString(@"LABEL_MODAL_POPUP_CLOSE_BUTTON", @"Text for modal popup close button"), ^{
			[plVC dismissViewControllerAnimated:YES completion:nil];
		});
	
		navVC.modalPresentationStyle = UIModalPresentationFormSheet;

		[self presentViewController:navVC animated:YES completion:nil];
		
	} else {
		
		WAEventPeopleListViewController *plVC = [[WAEventPeopleListViewController alloc] initWithStyle:UITableViewStylePlain];
		plVC.peopleList = [self.article.people allObjects];

		self.popover = [[UIPopoverController alloc] initWithContentViewController:plVC];
		[self.popover presentPopoverFromRect:CGRectMake(self.headerView.avatarPlacehoder.frame.size.width/2, self.headerView.avatarPlacehoder.frame.size.height - 25, 1, 1)
																	inView:self.headerView.avatarPlacehoder
								permittedArrowDirections:UIPopoverArrowDirectionUp
																animated:YES];
		
	}
	
}

- (void) addMorePeopleBtnPressed:(id)sender {
	
}

- (void) handleChangeDescription:(id)sender {
  
  __block WACompositionViewController *compositionVC = [WACompositionViewController defaultAutoSubmittingCompositionViewControllerForArticle:self.articleURL completion:^(NSURL *anArticleURLOrNil) {
	[compositionVC dismissViewControllerAnimated:YES completion:nil];
	compositionVC = nil;
  }];
  
  UINavigationController *wrapperNC = [compositionVC wrappingNavigationController];
  wrapperNC.modalPresentationStyle = UIModalPresentationFormSheet;
  
  [(self.navigationController ? self.navigationController : self) presentViewController:wrapperNC animated:YES completion:nil];

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
	
	if (!self.article.files.count)
		return isPad() ? 5 : 3; // add buttons placehoder
	
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

	CGFloat height = MAX(self.headerView.frame.size.height, CGRectGetMaxY(self.headerView.separatorLineBelowMap.frame));
	return (CGSize) { CGRectGetWidth(collectionView.frame), height + 7 };

}

#pragma mark - CollectionView delegate
- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	
	[NSException raise:NSInternalInconsistencyException format:@"Subclass shall implement %s", __PRETTY_FUNCTION__];

}


@end
