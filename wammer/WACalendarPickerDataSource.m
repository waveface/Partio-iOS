//
//  WACalendarPickerDataSource.m
//  wammer
//
//  Created by Greener Chen on 12/11/23.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WACalendarPickerDataSource.h"
#import "NSDate+WAAdditions.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

@interface WACalendarPickerDataSource	() <NSFetchedResultsControllerDelegate>

@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation WACalendarPickerDataSource

+ (WACalendarPickerDataSource *)dataSource
{
	return [[[self class] alloc] init];
}

- (id)init
{
	self = [super init];
	
	if (self) {
		_days = [[NSMutableArray alloc] init];
		_items = [[NSMutableArray alloc] init];
		_events = [[NSMutableArray alloc] init];
		_files = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (NSArray *)fetchAllArticlesFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
	NSFetchRequest *fetchRequest = [[WADataStore defaultStore].persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRArticles" substitutionVariables:@{}];
	
	fetchRequest.relationshipKeyPathsForPrefetching = @[
	@"files",
	@"tags",
	@"people",
	@"location",
	@"previews",
	@"descriptiveTags",
	@"files.pageElements"];
	fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[
														fetchRequest.predicate,
														[NSPredicate predicateWithFormat:@"creationDate >= %@ AND creationDate <= %@",
														 fromDate, toDate],
														[NSPredicate predicateWithFormat:@"event = TRUE"],
														[NSPredicate predicateWithFormat:@"files.@count > 0"],
														[NSPredicate predicateWithFormat:@"import != %d AND import != %d", WAImportTypeFromOthers, WAImportTypeFromLocal]]];
	
	fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
	
	self.fetchedResultsController = [[NSFetchedResultsController alloc]
																	 initWithFetchRequest:fetchRequest
																	 managedObjectContext:[[WADataStore defaultStore] defaultAutoUpdatedMOC]
																	 sectionNameKeyPath:nil
																	 cacheName:nil];
	
	self.fetchedResultsController.delegate = self;
	
	NSError *error = nil;
	
	if(![self.fetchedResultsController performFetch:&error]) {
		
		NSLog(@"%@: failed to fetch articles for events", __FUNCTION__);
		
	}

	return self.fetchedResultsController.fetchedObjects;
}

- (NSArray *)fetchAllFilesFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
	NSFetchRequest *fileFetchRequest = [[WADataStore defaultStore].persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRAllFiles" substitutionVariables:@{}];
	
	fileFetchRequest.predicate = [NSPredicate predicateWithFormat:@"created >= %@ AND created <= %@", fromDate, toDate];
	fileFetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"created" ascending:NO]];
	
	self.fetchedResultsController = [[NSFetchedResultsController alloc]
																	 initWithFetchRequest:fileFetchRequest
																	 managedObjectContext:[[WADataStore defaultStore] defaultAutoUpdatedMOC]
																	 sectionNameKeyPath:nil
																	 cacheName:nil];
	
	self.fetchedResultsController.delegate = self;
	
	NSError *error = nil;
	
	if(![self.fetchedResultsController performFetch:&error]) {
		
		NSLog(@"%@: failed to fetch articles for events", __FUNCTION__);
		
	}
	
	return self.fetchedResultsController.fetchedObjects;
}

- (void)loadDataDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate delegate:(id<KalDataSourceCallbacks>)delegate
{	
	// Load events and event days	
	_events = [[self fetchAllArticlesFrom:fromDate to:toDate] mutableCopy];
	
	__block NSDate *currentDate = nil;
	
	[_events enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		
		NSDate *theDate = nil;
		NSMutableDictionary *aDay = [@{
																 @"date": [NSDate date],
																 @"events": @0,
																 @"photos": @0
																 } mutableCopy];
		
		theDate = [[((WAArticle*)obj) creationDate] dayBegin];
		
		if (!currentDate || !isSameDay(currentDate, theDate)) {

			aDay[@"date"] = theDate;
			aDay[@"events"] = @1;
			[_days addObject:aDay];
			currentDate = theDate;
		
		}
		
	}];
	
	// Load photos and photo days
	_files = [[self fetchAllFilesFrom:fromDate to:toDate] mutableCopy];
		
	NSArray *fileOfDistinctDates = [_files valueForKeyPath:@"@distinctUnionOfObjects.created.dayBegin"];
	
	[fileOfDistinctDates enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		
		NSDate *date = obj;
		
		NSMutableDictionary *aDay = [@{
																 @"date": date,
																 @"events": @0,
																 @"photos": @0
																 } mutableCopy];
		
		NSPredicate *finder = [NSPredicate predicateWithFormat:@"date.dayBegin == %@", [date dayBegin]];
		NSMutableDictionary *targetSameDay = [[_days filteredArrayUsingPredicate:finder] lastObject];
		
		if (!targetSameDay) {
			
			aDay[@"date"] = date;
			aDay[@"photos"] = @1;
			[_days addObject:aDay];
		
		}
		else if([targetSameDay[@"photos"] isEqual:@0]) {
		
			targetSameDay[@"photos"] = @1;
			[_days replaceObjectAtIndex:[_days indexOfObject:targetSameDay] withObject:targetSameDay];
		
		}
		
	}];
	
	
	_days = [[_days sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
		NSDate *d1 = obj1[@"date"];
		NSDate *d2 = obj2[@"date"];
		return [d2 compare:d1];
	}] mutableCopy];

	
	[delegate loadedDataSource:self];
}

#pragma mark - KalDataSource protocol conformance

- (void)presentingDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate delegate:(id<KalDataSourceCallbacks>)delegate
{
	[self removeAllItems];
	[self loadDataDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate delegate:delegate];
}

- (NSArray *)markedDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
	NSPredicate *inRange = [NSPredicate predicateWithFormat:@"date BETWEEN %@",
													@[fromDate, toDate]];
	return [_days filteredArrayUsingPredicate:inRange];
}

- (void)loadItemsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
	
	[_items addObjectsFromArray:[self fetchAllArticlesFrom:fromDate to:toDate]];
	
	NSArray *filesOfDate = [self fetchAllFilesFrom:fromDate to:toDate];
	
	if ([filesOfDate count]) {
	
		[_items addObject:[filesOfDate lastObject]];
	
	}
}

- (void)removeAllItems
{
	[_days removeAllObjects];
	[_items removeAllObjects];
}

- (WAArticle *)eventAtIndexPath:(NSIndexPath *)indexPath
{
	return [_items objectAtIndex:indexPath.row];
}

#pragma mark - UITableViewDataSource protocol conformance

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *identifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
	}

	for (UIView *subview in cell.contentView.subviews)
		[subview removeFromSuperview];
		
	if (![_items count]) {
		UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(54, 0, 200, 54)];
		[title setText:NSLocalizedString(@"CALENDAR_NO_EVENT", "Description for no event day in calendar")];
		[title setTextAlignment:NSTextAlignmentCenter];
		[title setFont:[UIFont boldSystemFontOfSize:16.f]];
		[title setTextColor:[UIColor grayColor]];
		[title setBackgroundColor:[UIColor colorWithRed:0.89f green:0.89f blue:0.89f alpha:1.f]];
		[cell.contentView addSubview:title];
		
		[cell setAccessoryView:nil];
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	}
	else {
		id item = [self eventAtIndexPath:indexPath];
		
		if ([item isKindOfClass:[WAArticle class]]) {
			WAArticle *event = item;
			
			// TODO: show thumbnail images in kvo way
			UIImageView *thumbnail = [[UIImageView alloc] initWithImage:event.representingFile.extraSmallThumbnailImage];
			[thumbnail setBackgroundColor:[UIColor grayColor]];
			[thumbnail setBounds:CGRectMake(4, 4, 45, 45)];
			[thumbnail setFrame:CGRectMake(4, 4, 45, 45)];
			[thumbnail setClipsToBounds:YES];
			[cell.contentView addSubview:thumbnail];
			
			UILabel *title = [[UILabel alloc] init];
			title.attributedText = [[self class] attributedDescStringforEvent:event];
			[title setBackgroundColor:[UIColor colorWithRed:0.89f green:0.89f blue:0.89f alpha:1.f]];
			title.numberOfLines = 0;
			[title setFrame:CGRectMake(60, 0, 220, 54)];
			[cell.contentView addSubview:title];
			[cell setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EventCameraIcon"]]];
		}
		
		if ([item isKindOfClass:[WAFile class]]) {
			
			WAFile *file = item;
			
			UIImageView *thumbnail = [[UIImageView alloc] initWithImage:file.extraSmallThumbnailImage];
			[thumbnail setBackgroundColor:[UIColor grayColor]];
			[thumbnail setBounds:CGRectMake(4, 4, 45, 45)];
			[thumbnail setFrame:CGRectMake(4, 4, 45, 45)];
			[thumbnail setClipsToBounds:YES];
			[cell.contentView addSubview:thumbnail];

			UILabel *title = [[UILabel alloc] init];
			[title setText:@"PHOTOS"];
			[title setBackgroundColor:[UIColor colorWithRed:0.89f green:0.89f blue:0.89f alpha:1.f]];
			title.numberOfLines = 0;
			[title setFrame:CGRectMake(60, 0, 220, 54)];
			[cell.contentView addSubview:title];
			
			[cell setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PhotosIcon"]]];

		}
		
		[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
	}
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (![_items count])
		return 1;
	
	return [_items count];
}

#pragma mark -

+ (NSAttributedString *)attributedDescStringforEvent:(WAArticle *)event
{
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
		
	UIFont *hlFont = [UIFont fontWithName:@"Georgia-Italic" size:14.0f];
	UIFont *bFont = [UIFont boldSystemFontOfSize:14.f];
	
	NSString *locString = [locations componentsJoinedByString:@","];
	NSString *peoString = [people componentsJoinedByString:@","];
	NSMutableString *rawString = nil;
	
	if (event.eventDescription && event.eventDescription.length) {
		rawString = [NSMutableString stringWithFormat:@"%@", event.eventDescription];
	} else {
		rawString = [NSMutableString string];
	}
	
	if (locations && locations.count) {
		[rawString appendFormat:@"At %@", locString];
	}
	
	if (people && people.count) {
		[rawString appendFormat:@" With %@.", peoString];
	}
		
	NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:rawString];
	
	UIColor *descColor = [UIColor colorWithRed:0.353f green:0.361f blue:0.361f alpha:1.f];
	
	NSDictionary *actionAttr = @{NSForegroundColorAttributeName: descColor, NSFontAttributeName: hlFont};
	NSDictionary *locationAttr = @{NSForegroundColorAttributeName: descColor, NSFontAttributeName: hlFont};
	NSDictionary *peopleAttr = @{NSForegroundColorAttributeName: descColor, NSFontAttributeName: hlFont};
	NSDictionary *othersAttr = @{NSForegroundColorAttributeName: descColor, NSFontAttributeName: bFont};
	
	[attrString setAttributes:othersAttr range:(NSRange)[rawString rangeOfString:rawString]];
	if (event.eventDescription && event.eventDescription.length > 0)
		[attrString setAttributes:actionAttr range:(NSRange){0, event.eventDescription.length}];
	if (locString && locString.length > 0 )
		[attrString setAttributes:locationAttr range:(NSRange)[rawString rangeOfString:locString]];
	if (peoString && peoString.length > 0 )
		[attrString setAttributes:peopleAttr range:(NSRange)[rawString rangeOfString:peoString]];
	
	return attrString;
}

@end