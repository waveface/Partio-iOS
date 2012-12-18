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
#import "WADayViewController.h"

@interface WACalendarPickerDataSource	() <NSFetchedResultsControllerDelegate>

@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, strong) NSFetchedResultsController *fetchedResultsController;

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

- (void)loadDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
	/*
	 * dot marker types:
	 * - markedRed: Events
	 * - markedLightBlue: Photos
	 * - markedOrange: Documents
	 * - markedGreen:
	 * - markedDarkBlue:
	 */
		
	WADayViewController *dVC = [WADayViewController alloc];
	[dVC loadDaysWithStyle:WADayViewStyleTimeline From:fromDate to:toDate completionBlock:^(NSArray *days){
	
		for (NSDate *day in days) {
			[_daysWithAttributes addObject:[[NSMutableDictionary alloc]
																			initWithObjects:@[day, @YES, @NO, @NO, @NO, @NO]
																			forKeys:@[@"date", @"markedRed", @"markedLightBlue", @"markedOrange", @"markedGreen", @"markedDarkBlue"]]];
		}
		
	}];
	
	
	[dVC loadDaysWithStyle:WADayViewStylePhotoStream From:fromDate to:toDate completionBlock:^(NSArray *days){
	
		for (NSDate *day in days) {
			NSPredicate *finder = [NSPredicate predicateWithFormat:@"date == %@", day];
			NSMutableDictionary *dayWithEvent = [[_daysWithAttributes filteredArrayUsingPredicate:finder] lastObject];
			
			if (!dayWithEvent) {
				[_daysWithAttributes addObject:[[NSMutableDictionary alloc]
																				initWithObjects:@[day, @NO, @YES, @NO, @NO, @NO]
																				forKeys:@[@"date", @"markedRed", @"markedLightBlue", @"markedOrange", @"markedGreen", @"markedDarkBlue"]]];
			} else {
				NSMutableDictionary *modifiedObject = [dayWithEvent mutableCopy];
				[modifiedObject setValue:@YES forKey:@"markedLightBlue"];
				
				[_daysWithAttributes replaceObjectAtIndex:[_daysWithAttributes indexOfObject:dayWithEvent] withObject:modifiedObject];
				
			}
		}

	}];
	
	
	[dVC loadDaysWithStyle:WADayViewStyleDocumentStream From:fromDate to:toDate completionBlock:^(NSArray *days){
		
		for (NSDate *day in days) {
			NSPredicate *finder = [NSPredicate predicateWithFormat:@"date == %@", day];
			NSMutableDictionary *dayWithEventPhoto = [[_daysWithAttributes filteredArrayUsingPredicate:finder] lastObject];
			
			if (!dayWithEventPhoto) {
				[_daysWithAttributes addObject:[[NSMutableDictionary alloc]
																				initWithObjects:@[day, @NO, @NO, @YES, @NO, @NO]
																				forKeys:@[@"date", @"markedRed", @"markedLightBlue", @"markedOrange", @"markedGreen", @"markedDarkBlue"]]];
			} else {
				NSMutableDictionary *modifiedObject = [dayWithEventPhoto mutableCopy];
				[modifiedObject setValue:@YES forKey:@"markedOrange"];
				
				[_daysWithAttributes replaceObjectAtIndex:[_daysWithAttributes indexOfObject:dayWithEventPhoto] withObject:modifiedObject];
			}
		}

	}];
	
}

- (NSArray *)fetchEventsFrom:(NSDate *)fromDate to:(NSDate *)toDate
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
														[NSPredicate predicateWithFormat:@"event == TRUE"],
														[NSPredicate predicateWithFormat:@"import != %d AND import != %d", WAImportTypeFromOthers, WAImportTypeFromLocal]]];
	
	if (fromDate && toDate) {
		fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[
															fetchRequest.predicate,
															[NSPredicate predicateWithFormat:@"creationDate >= %@ AND creationDate <= %@", fromDate, toDate]]];
	}
	
	fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
	
	self.fetchedResultsController = [[NSFetchedResultsController alloc]
																	 initWithFetchRequest:fetchRequest
																	 managedObjectContext:[[WADataStore defaultStore] defaultAutoUpdatedMOC]
																	 sectionNameKeyPath:nil
																	 cacheName:nil];
	self.fetchedResultsController.delegate = self;
	
	NSError *err = nil;
	if (![self.fetchedResultsController performFetch:&err]) 
		NSLog(@"%@: failed to fetch articles for events", __FUNCTION__);
	
	return self.fetchedResultsController.fetchedObjects;

}

- (NSArray *)fetchPhotosFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
	NSFetchRequest *fetchReqest = [[WADataStore defaultStore].persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRAllFiles" substitutionVariables:@{}];
	
	if (fromDate && toDate) {
		fetchReqest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[
														 //fetchReqest.predicate,
														 [NSPredicate predicateWithFormat:@"created >= %@ AND created <= %@", fromDate, toDate]]];
	}
	
	fetchReqest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"created" ascending:NO]];
	
	self.fetchedResultsController = [[NSFetchedResultsController alloc]
																	 initWithFetchRequest:fetchReqest
																	 managedObjectContext:[[WADataStore defaultStore] defaultAutoUpdatedMOC]
																	 sectionNameKeyPath:nil
																	 cacheName:nil];
	self.fetchedResultsController.delegate = self;
	
	NSError *err = nil;
	if (![self.fetchedResultsController performFetch:&err])
		NSLog(@"%@: failed to fetch photos", __FUNCTION__);
	
	return self.fetchedResultsController.fetchedObjects;
	
}

- (NSArray *)fetchDocsFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
	NSFetchRequest *fetchRequest = [[WADataStore defaultStore].persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRAllFiles" substitutionVariables:@{}];
	
	if (fromDate && toDate) {
		fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[
															//fetchRequest.predicate,
															[NSPredicate predicateWithFormat:@"docAccessTime >= %@ AND docAccessTime <= %@", fromDate, toDate]]];
	}
	
	fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"docAccessTime" ascending:NO]];
	
	self.fetchedResultsController = [[NSFetchedResultsController alloc]
																	 initWithFetchRequest:fetchRequest
																	 managedObjectContext:[[WADataStore defaultStore] defaultAutoUpdatedMOC]
																	 sectionNameKeyPath:nil
																	 cacheName:nil];
	self.fetchedResultsController.delegate = self;
	
	NSError *err = nil;
	if (![self.fetchedResultsController performFetch:&err])
		NSLog(@"%@: failed to fetch docs", __FUNCTION__);
	
	return self.fetchedResultsController.fetchedObjects;

}

#pragma mark - KalDataSource protocol conformance

- (void)presentingDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate delegate:(id<KalDataSourceCallbacks>)delegate
{
	[_daysWithAttributes removeAllObjects];
	[self loadDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate];
	[delegate loadedDataSource:self];

}

- (NSArray *)markedDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
	NSPredicate *inRange = [NSPredicate predicateWithFormat:@"date >= %@ AND date <= %@", fromDate, toDate];
	return [_daysWithAttributes filteredArrayUsingPredicate:inRange];
}

- (void)loadItemsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
	[_items addObjectsFromArray:[self fetchEventsFrom:fromDate to:toDate]];
	
	NSArray *photo = [self fetchPhotosFrom:fromDate to:toDate];
	if ([photo count]) {
		[_items addObject:[photo lastObject]];
	
	}

	NSArray *doc = [self fetchDocsFrom:fromDate to:toDate];
	if ([doc count]) {		
		[_items addObject:[doc lastObject]];
		
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
		UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(54, 0, 200 , 54)];
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
			
			if (file.created) {
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

			} else if (file.docAccessTime) {
				[cell.textLabel setText:@"Documents"];
				
			}
			
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