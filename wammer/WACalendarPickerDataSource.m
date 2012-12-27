//
//  WACalendarPickerDataSource.m
//  wammer
//
//  Created by Greener Chen on 12/11/23.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WACalendarPickerDataSource.h"
#import "WACalendarPickerPanelViewCell.h"
#import "NSDate+WAAdditions.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"
#import "WAEventViewController.h"
#import "WADayViewController.h"
#import "WAFileAccessLog.h"

NSString *const kMarkedEvents = @"markedRed";
NSString *const kMarkedPhotos = @"markedLightBlue";
NSString *const kMarkedDocuments = @"markedOrange";
NSString *const kMarkedWebpages = @"markedGreen";
NSString *const kMarkedCollections = @"markedDarkBlue";

@interface WACalendarPickerDataSource () <NSFetchedResultsControllerDelegate>

typedef void (^completionBlock) (NSArray *days);
@property (nonatomic, readwrite, copy) completionBlock callback;


@end

@implementation WACalendarPickerDataSource

- (id)init
{
	self = [super init];
	
	if (self) {
		_daysWithAttributes = [[NSMutableArray alloc] init];
		_items = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void)loadDayswithStyle:(WACalendarLoadObject)style from:(NSDate *)fromDate to:(NSDate *)toDate completionBlock:(completionBlock)block
{
	NSString *entityName = nil;
	
	if (style == WACalendarLoadObjectEvent) {
		entityName = @"WAEventDay";
		
	} else if (style == WACalendarLoadObjectPhoto) {
		
		entityName = @"WAPhotoDay";
		
	} else if (style == WACalendarLoadObjectDoc) {
		
		entityName = @"WADocumentDay";
		
	}
	
	NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
	[request setEntity:entity];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"day" ascending:NO];
	[request setSortDescriptors:@[sortDescriptor]];
	
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
		
	NSError *error = nil;
	
	if(![fetchedResultsController performFetch:&error]) {
		NSLog(@"%@: failed to fetch files for documents", __FUNCTION__);
	}
	
	if (block) {
		self.callback = block;
		NSArray *passingDays = [fetchedResultsController.fetchedObjects isKindOfClass:[NSNull class]]? nil: [fetchedResultsController.fetchedObjects valueForKey:@"day"];
		self.callback(passingDays);
	}
}

- (void)fetchDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
	
	[self loadDayswithStyle:WACalendarLoadObjectEvent from:fromDate to:toDate completionBlock:^(NSArray *days){
		
		for (NSDate *day in days) {
			[_daysWithAttributes addObject: [@{@"date": day,
											 kMarkedEvents: @YES,
											 kMarkedPhotos: @NO,
										kMarkedDocuments: @NO,
										 kMarkedWebpages: @NO,
									kMarkedCollections: @NO} mutableCopy]];
			
		}
		
	}];
	
	
	[self loadDayswithStyle:WACalendarLoadObjectPhoto from:fromDate to:toDate completionBlock:^(NSArray *days){
		
		for (NSDate *day in days) {
			NSPredicate *finder = [NSPredicate predicateWithFormat:@"date == %@", day];
			NSMutableDictionary *dayWithEvent = [[_daysWithAttributes filteredArrayUsingPredicate:finder] lastObject];
			
			if (!dayWithEvent) {
				[_daysWithAttributes addObject: [@{@"date": day,
												 kMarkedEvents: @NO,
												 kMarkedPhotos: @YES,
											kMarkedDocuments: @NO,
											 kMarkedWebpages: @NO,
										kMarkedCollections: @NO} mutableCopy]];
			} else {
				NSMutableDictionary *modifiedObject = [dayWithEvent mutableCopy];
				modifiedObject[kMarkedPhotos] = @YES;
				
				[_daysWithAttributes replaceObjectAtIndex:[_daysWithAttributes indexOfObject:dayWithEvent] withObject:modifiedObject];
				
			}
		}
		
	}];
	
	
	[self loadDayswithStyle:WACalendarLoadObjectDoc from:fromDate to:toDate completionBlock:^(NSArray *days){
		
		for (NSDate *day in days) {
			NSPredicate *finder = [NSPredicate predicateWithFormat:@"date == %@", day];
			NSMutableDictionary *dayWithEventPhoto = [[_daysWithAttributes filteredArrayUsingPredicate:finder] lastObject];
			
			if (!dayWithEventPhoto) {
				[_daysWithAttributes addObject:[@{@"date": day,
												 kMarkedEvents: @NO,
												 kMarkedPhotos: @NO,
											kMarkedDocuments: @YES,
											 kMarkedWebpages: @NO,
										kMarkedCollections: @NO} mutableCopy]];
			} else {
				NSMutableDictionary *modifiedObject = [dayWithEventPhoto mutableCopy];
				modifiedObject[kMarkedDocuments] = @YES;
				
				[_daysWithAttributes replaceObjectAtIndex:[_daysWithAttributes indexOfObject:dayWithEventPhoto] withObject:modifiedObject];
			}
		}
		
	}];
	
}

- (NSArray *)fetchObject:(WACalendarLoadObject)object from:(NSDate *)fromDate to:(NSDate *)toDate
{
	NSString *entityName = nil;
	NSArray *relationshipKeyPath = nil;
	NSString *predicateStr = nil;
	NSString *sortKey = nil;
	
	if (object == WACalendarLoadObjectEvent) {
		entityName = @"WAArticle";
		relationshipKeyPath = @[@"files"];
		predicateStr = @"event == TRUE AND creationDate >= %@ AND creationDate <= %@";
		sortKey = @"creationDate";
		
	} else if (object == WACalendarLoadObjectPhoto ) {
		entityName = @"WAFile";
		relationshipKeyPath = @[];
		predicateStr = @"created >= %@ AND created <= %@";
		sortKey = @"created";
		
	} else if (object == WACalendarLoadObjectDoc) {
		entityName = @"WAFileAccessLog";
		relationshipKeyPath = @[@"day", @"dayWebpages", @"file"];
		predicateStr = @"accessTime >= %@ AND accessTime <= %@";
		sortKey = @"accessTime";
		
	}
	
	NSManagedObjectContext *moc = [[WADataStore defaultStore] autoUpdatingMOC];
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:moc];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:entity];
	fetchRequest.relationshipKeyPathsForPrefetching = relationshipKeyPath;
	NSPredicate *dayRange = [NSPredicate predicateWithFormat:predicateStr, fromDate, toDate];
	[fetchRequest setPredicate:dayRange];
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:sortKey ascending:NO];
	[fetchRequest setSortDescriptors:@[sortDescriptor]];
	
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
	
	NSError *error = nil;
	if (![fetchedResultsController performFetch:&error]) {
		NSLog(@"%@: failed to fetch objects for %@", __FUNCTION__, predicateStr);
		
	}
	
	return [fetchedResultsController.fetchedObjects copy];
}

#pragma mark - KalDataSource protocol conformance

- (void)presentingDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate delegate:(id<KalDataSourceCallbacks>)delegate
{
	[_daysWithAttributes removeAllObjects];
	[self fetchDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate];
	[delegate loadedDataSource:self];
	
}

- (NSArray *)markedDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
	NSPredicate *inRange = [NSPredicate predicateWithFormat:@"date >= %@ AND date <= %@", fromDate, toDate];
	return [[_daysWithAttributes filteredArrayUsingPredicate:inRange] copy];
}

- (void)loadItemsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
	[_items addObjectsFromArray:[self fetchObject:WACalendarLoadObjectEvent from:fromDate to:toDate]];
	_selectedNSDate = fromDate;
	
}

- (void)removeAllItems
{
	[_items removeAllObjects];
}

- (WAArticle *)eventAtIndexPath:(NSIndexPath *)indexPath
{
	return [_items objectAtIndex:indexPath.row];
}

#pragma mark - UITableViewDataSource protocol conformance

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *identifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
	} 
	
	for (UIView *subview in cell.contentView.subviews)
		[subview removeFromSuperview];
	
	for (UIView *subview in cell.accessoryView.subviews)
		[subview removeFromSuperview];
	
	if (!_items.count && indexPath.row == 0) {
		UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(54, 0, 200 , 54)];
		[title setText:NSLocalizedString(@"CALENDAR_NO_EVENT", "Description for no event day in calendar")];
		[title setTextAlignment:NSTextAlignmentCenter];
		[title setFont:[UIFont boldSystemFontOfSize:16.f]];
		[title setTextColor:[UIColor grayColor]];
		[title setBackgroundColor:[UIColor clearColor]];
		[cell.contentView addSubview:title];
		
		[cell setAccessoryView:nil];
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	
	} else if ((_items.count && indexPath.row == _items.count) || (!_items.count && indexPath.row == 1)) {
		cell = [[WACalendarPickerPanelViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"IconsCell"];
		
	} else {
		id item = [self eventAtIndexPath:indexPath];
		
		WAArticle *event = item;
		UIImage *xsThumbnail = event.representingFile.extraSmallThumbnailImage;
		
		UIImageView *thumbnail = [[UIImageView alloc] initWithImage:xsThumbnail?xsThumbnail:nil];
		[thumbnail setBackgroundColor:[UIColor grayColor]];
		[thumbnail setFrame:CGRectMake(4, 4, 45, 45)];
		[thumbnail setClipsToBounds:YES];
		[cell.contentView addSubview:thumbnail];
		
		UILabel *title = [[UILabel alloc] init];
		title.attributedText = [[WAEventViewController class] attributedDescriptionStringForEvent:event styleWithColor:NO styleWithFontForTableView:YES];
		[title setBackgroundColor:[UIColor clearColor]];
		title.numberOfLines = 0;
		[title setFrame:CGRectMake(60, 0, 220, 54)];
		[cell.contentView addSubview:title];
		[cell setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EventCameraIcon"]]];
		
		[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
		
	}
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger count = _items.count + 1;
	if (!_items.count)
		count = 2;
	
	return count;
}

@end