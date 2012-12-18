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
#import "WAFileAccessLog.h"

@interface WACalendarPickerDataSource	() <NSFetchedResultsControllerDelegate>

@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, strong) NSFetchedResultsController *fetchedResultsController;

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
	
	NSManagedObjectContext *context = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
	[request setEntity:entity];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"day" ascending:NO];
	[request setSortDescriptors:@[sortDescriptor]];
	
	self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
	
	self.fetchedResultsController.delegate = self;
	
	NSError *error = nil;
	
	if(![self.fetchedResultsController performFetch:&error]) {
		NSLog(@"%@: failed to fetch files for documents", __FUNCTION__);
	}

	NSArray *passingDays = [self.fetchedResultsController.fetchedObjects isKindOfClass:[NSNull class]]? nil: [self.fetchedResultsController.fetchedObjects valueForKey:@"day"];
	self.callback = block;
	if (self.callback)
		self.callback(passingDays);
	
}

- (void)fetchDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
	/*
	 * dot marker types:
	 * - markedRed: Events
	 * - markedLightBlue: Photos
	 * - markedOrange: Documents
	 * - markedGreen:
	 * - markedDarkBlue:
	 */
		
	[self loadDayswithStyle:WACalendarLoadObjectEvent from:fromDate to:toDate completionBlock:^(NSArray *days){
	
		for (NSDate *day in days) {
			[_daysWithAttributes addObject:[[NSMutableDictionary alloc]
																			initWithObjects:@[day, @YES, @NO, @NO, @NO, @NO]
																			forKeys:@[@"date", @"markedRed", @"markedLightBlue", @"markedOrange", @"markedGreen", @"markedDarkBlue"]]];
		}
		
	}];
	
	
	[self loadDayswithStyle:WACalendarLoadObjectPhoto from:fromDate to:toDate completionBlock:^(NSArray *days){
	
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
	
	
	[self loadDayswithStyle:WACalendarLoadObjectDoc from:fromDate to:toDate completionBlock:^(NSArray *days){
		
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
	
	NSManagedObjectContext *moc = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
	NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:moc];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:entity];
	fetchRequest.relationshipKeyPathsForPrefetching = relationshipKeyPath;
	NSPredicate *dayRange = [NSPredicate predicateWithFormat:predicateStr, fromDate, toDate];
	[fetchRequest setPredicate:dayRange];
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:sortKey ascending:NO];
	[fetchRequest setSortDescriptors:@[sortDescriptor]];
	
	self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
	self.fetchedResultsController.delegate = self;
	
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
		NSLog(@"%@: failed to fetch objects for %@", __FUNCTION__, predicateStr);
		
	}

	return self.fetchedResultsController.fetchedObjects;
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
	return [_daysWithAttributes filteredArrayUsingPredicate:inRange];
}

- (void)loadItemsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
	[_items addObjectsFromArray:[self fetchObject:WACalendarLoadObjectEvent from:fromDate to:toDate]];
	
	NSArray *photo = [self fetchObject:WACalendarLoadObjectPhoto from:fromDate to:toDate];
	if ([photo count]) {
		[_items addObject:[photo lastObject]];
	
	}

	NSArray *doc = [self fetchObject:WACalendarLoadObjectDoc from:fromDate to:toDate];
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
			
		} else if ([item isKindOfClass:[WAFile class]]) {
			
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
				
			}
			
		} else if ([item isKindOfClass:[WAFileAccessLog class]]) {
				[cell.textLabel setText:@"Documents"];
				[cell setAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DocumentsIcon"]]];
		
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