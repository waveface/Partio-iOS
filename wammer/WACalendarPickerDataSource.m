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

NSString *const kMarkedEvents = @"markedRed";
NSString *const kMarkedPhotos = @"markedOrange";
NSString *const kMarkedDocuments = @"markedGreen";
NSString *const kMarkedWebpages = @"markedLightBlue";
NSString *const kMarkedCollections = @"markedDarkBlue";

typedef NS_ENUM(NSInteger, WACalendarLoadObject) {
  WACalendarLoadObjectEvent,
  WACalendarLoadObjectPhoto,
  WACalendarLoadObjectDoc,
  WACalendarLoadObjectWebpage
};

@interface WACalendarPickerDataSource () <NSFetchedResultsControllerDelegate>

typedef void (^completionBlock) (NSArray *days);
@property (nonatomic, strong) NSMutableArray *daysWithAttributes;
@property (nonatomic, strong)	NSMutableArray *items;

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
		
  } else if (style == WACalendarLoadObjectWebpage) {
	
	entityName = @"WAWebpageDay";
  }
  
  NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
  NSFetchRequest *request = [[NSFetchRequest alloc] init];
  NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
  [request setEntity:entity];
  request.predicate = [NSPredicate predicateWithFormat:@"( %@ <= day ) AND ( day <= %@ )", fromDate, toDate];
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"day" ascending:NO];
  [request setSortDescriptors:@[sortDescriptor]];
	
  NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
		
  NSError *error = nil;
	
  if(![fetchedResultsController performFetch:&error]) {
	NSLog(@"%@: failed to fetch files for documents", __FUNCTION__);
  }
	
  if (block) {
	NSArray *passingDays = [fetchedResultsController.fetchedObjects isKindOfClass:[NSNull class]]? nil: [fetchedResultsController.fetchedObjects valueForKey:@"day"];
	
	block(passingDays);
  }
}

- (void)fetchDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  [self loadDayswithStyle:WACalendarLoadObjectEvent from:fromDate to:toDate completionBlock:^(NSArray *days){
	
	for (NSDate *day in days) {
	  dict[day] = [@{@"date": day,
				   kMarkedEvents: @YES,
				   kMarkedPhotos: @NO,
				   kMarkedDocuments: @NO,
				   kMarkedWebpages: @NO,
				   kMarkedCollections: @NO} mutableCopy];
			
	}
		
  }];
	
	
  [self loadDayswithStyle:WACalendarLoadObjectPhoto from:fromDate to:toDate completionBlock:^(NSArray *days){
		
	for (NSDate *day in days) {
	  NSMutableDictionary *attr = dict[day];
	  if (!attr) {
		dict[day] = [@{@"date": day,
					 kMarkedEvents: @NO,
					 kMarkedPhotos: @YES,
					 kMarkedDocuments: @NO,
					 kMarkedWebpages: @NO,
					 kMarkedCollections: @NO} mutableCopy];
	  } else {
		attr[kMarkedPhotos] = @YES;
		
	  }
	}
		
  }];
	
	
  [self loadDayswithStyle:WACalendarLoadObjectDoc from:fromDate to:toDate completionBlock:^(NSArray *days){
		
	for (NSDate *day in days) {
	  NSMutableDictionary *attr = dict[day];
	  if (!attr) {
		dict[day] = [@{@"date": day,
					 kMarkedEvents: @NO,
					 kMarkedPhotos: @NO,
					 kMarkedDocuments: @YES,
					 kMarkedWebpages: @NO,
					 kMarkedCollections: @NO} mutableCopy];
	  } else {
		
		attr[kMarkedDocuments] = @YES;
			
	  }
	}
		
  }];
	
  [self loadDayswithStyle:WACalendarLoadObjectWebpage from:fromDate to:toDate completionBlock:^(NSArray *days) {
		
	for (NSDate *day in days) {
	  NSMutableDictionary *attr = dict[day];
	  if (!attr) {
		dict[day] = [@{@"date": day,
					 kMarkedEvents: @NO,
					 kMarkedPhotos: @NO,
					 kMarkedDocuments: @NO,
					 kMarkedWebpages: @YES,
					 kMarkedCollections: @NO} mutableCopy];
	  } else {
		
		attr[kMarkedWebpages] = @YES;
			
	  }
		
	}
		
  }];
  
  __weak WACalendarPickerDataSource *wSelf = self;
  [dict enumerateKeysAndObjectsUsingBlock:^(id key, NSMutableDictionary *attrs, BOOL *stop) {
	[wSelf.daysWithAttributes addObject:attrs];
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
  [self.daysWithAttributes removeAllObjects];
  [self fetchDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate];
  [delegate loadedDataSource:self];
	
}

- (NSArray *)markedDatesFrom:(NSDate *)fromDate to:(NSDate *)toDate
{
  NSPredicate *inRange = [NSPredicate predicateWithFormat:@"date >= %@ AND date <= %@", fromDate, toDate];
  return [[self.daysWithAttributes filteredArrayUsingPredicate:inRange] copy];
}

- (void)loadItemsFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate
{
  
  [self.items addObjectsFromArray:[self fetchObject:WACalendarLoadObjectEvent from:fromDate to:toDate]];
	
}

- (void)removeAllItems
{
  [self.items removeAllObjects];
}

- (WAArticle *)eventAtIndexPath:(NSIndexPath *)indexPath
{
  return [self.items objectAtIndex:indexPath.row];
}

#pragma mark - UITableViewDataSource protocol conformance

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *identifier = @"Cell";
  static NSString *noCellIdentifier = @"NoEventCell";
  UITableViewCell *cell = nil;

  if (!self.items.count && indexPath.row == 0) {
	cell = [tableView dequeueReusableCellWithIdentifier:noCellIdentifier];
	if (!cell)
	  cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:noCellIdentifier];

	UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(54, 0, 200 , 54)];
	[title setText:NSLocalizedString(@"CALENDAR_NO_EVENT", "Description for no event day in calendar")];
	[title setTextAlignment:NSTextAlignmentCenter];
	[title setFont:[UIFont boldSystemFontOfSize:16.f]];
	[title setTextColor:[UIColor grayColor]];
	[title setBackgroundColor:[UIColor clearColor]];
	[cell.contentView addSubview:title];
		
	[cell setAccessoryView:nil];
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	
  } else {
	cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	if (!cell)
	  cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
	
	
	for (UIView *subview in cell.contentView.subviews)
	  [subview removeFromSuperview];
	
	for (UIView *subview in cell.accessoryView.subviews)
	  [subview removeFromSuperview];
	 
	id item = [self eventAtIndexPath:indexPath];
		
	WAArticle *event = (WAArticle*)item;
		
	[event irObserve:@"representingFile.extraSmallThumbnailImage"
			 options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
			 context:nil
		   withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {

			 UIImageView *thumbnail = [[UIImageView alloc] initWithImage:(UIImage *)toValue];
			 [thumbnail setBackgroundColor:[UIColor grayColor]];
			 [thumbnail setFrame:CGRectMake(4, 4, 45, 45)];
			 [thumbnail setClipsToBounds:YES];
			 [cell.contentView addSubview:thumbnail];

		   }];

		
	static UIImage *eventCameraIcon;
	eventCameraIcon = [UIImage imageNamed:@"EventCameraIcon"];
	UILabel *title = [[UILabel alloc] init];
	title.attributedText = [[WAEventViewController class] attributedDescriptionStringForEvent:event styleWithColor:NO styleWithFontForTableView:YES];
	[title setBackgroundColor:[UIColor clearColor]];
	title.numberOfLines = 0;
	[title setFrame:CGRectMake(60, 0, 220, 54)];
	[cell.contentView addSubview:title];
	[cell setAccessoryView:[[UIImageView alloc] initWithImage:eventCameraIcon]];
		
	[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
		
  }
	
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  NSInteger count = self.items.count;
  if (!self.items.count)
	count = 1;
	
  return count;
}

@end