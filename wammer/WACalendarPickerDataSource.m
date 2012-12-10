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
#import "WAEventViewController.h"

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

- (void)loadDataFrom:(NSDate *)fromDate to:(NSDate *)toDate
{	
	// Load events and event days	
	_events = [[self fetchAllArticlesFrom:fromDate to:toDate] mutableCopy];
	
	__block NSDate *currentDate = nil;
	
	[_events enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		
		NSDate *theDate = nil;
		NSMutableDictionary *aDay = [@{
																 @"date": [NSDate date],
																 @"markedRed": @NO,
																 @"photos": @NO, @"markedLightBlue": @NO,
																 } mutableCopy];
		
		theDate = [[((WAArticle*)obj) creationDate] dayBegin];
		
		if (!currentDate || !isSameDay(currentDate, theDate)) {

			aDay[@"date"] = [theDate dayBegin];
			aDay[@"markedRed"] = @YES;
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
																 @"markedRed": @NO,
																 @"photos": @NO, @"markedLightBlue": @NO,
																 } mutableCopy];
		
		NSPredicate *finder = [NSPredicate predicateWithFormat:@"date.dayBegin == %@", [date dayBegin]];
		NSMutableDictionary *dayWithEvent = [[_days filteredArrayUsingPredicate:finder] lastObject];
		
		if (!dayWithEvent) {
			
			aDay[@"date"] = [date dayBegin];
			aDay[@"markedLightBlue"] = @YES;
			[_days addObject:aDay];
		
		}
		else if([dayWithEvent[@"photos"] isEqual:@NO]) {
		
			dayWithEvent[@"markedLightBlue"] = @YES;
			[_days replaceObjectAtIndex:[_days indexOfObject:dayWithEvent] withObject:dayWithEvent];
		
		}
		
	}];
	
}

#pragma mark - KalDataSource protocol conformance

- (void)presentingDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate delegate:(id<KalDataSourceCallbacks>)delegate
{
	[_days removeAllObjects];
	[_events removeAllObjects];
	[_files removeAllObjects];
	[self loadDataFrom:(NSDate *)fromDate to:(NSDate *)toDate];
	[delegate loadedDataSource:self];

}

- (NSArray *)markedDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
	NSPredicate *inRange = [NSPredicate predicateWithFormat:@"date BETWEEN %@", @[fromDate, toDate]];
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
			
			// TODO: show event / thumbnail images in kvo way?
			UIImageView *thumbnail = [[UIImageView alloc] initWithImage:event.representingFile.extraSmallThumbnailImage];
			[thumbnail setBackgroundColor:[UIColor grayColor]];
			[thumbnail setFrame:CGRectMake(4, 4, 45, 45)];
			[thumbnail setClipsToBounds:YES];
			[cell.contentView addSubview:thumbnail];
			
			UILabel *title = [[UILabel alloc] init];
			title.attributedText = [[WAEventViewController class] attributedDescriptionStringForEvent:event styleWithColor:NO styleWithFontForTableView:YES];
			[title setBackgroundColor:[UIColor colorWithRed:0.89f green:0.89f blue:0.89f alpha:1.f]];
			title.numberOfLines = 0;
			[title setFrame:CGRectMake(60, 0, 220, 54)];
			[cell.contentView addSubview:title];
			[cell setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EventCameraIcon"]]];
		}
		else if ([item isKindOfClass:[WAFile class]]) {
			
			WAFile *file = item;
			
			UIImageView *thumbnail = [[UIImageView alloc] initWithImage:file.extraSmallThumbnailImage];
			[thumbnail setBackgroundColor:[UIColor grayColor]];
			[thumbnail setFrame:CGRectMake(4, 4, 45, 45)];
			[thumbnail setClipsToBounds:YES];
			[cell.contentView addSubview:thumbnail];

			UILabel *title = [[UILabel alloc] init];
			[title setText:NSLocalizedString(@"SLIDING_MENU_TITLE_PHOTOS", @"Title for Photos in the sliding menu")];
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
	NSInteger count = [_items count];
	
	if (!count)
		return 1;
	
	return count;
}

@end