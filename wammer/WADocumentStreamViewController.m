//
//  WADocumentStreamViewController.m
//  wammer
//
//  Created by kchiu on 12/12/5.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WADocumentStreamViewController.h"
#import "WADocumentStreamViewCell.h"
#import "Foundation+IRAdditions.h"
#import "WADataStore.h"

@interface WADocumentStreamViewController ()

@property (nonatomic, readwrite, strong) NSDate *startDate;
@property (nonatomic, readwrite, strong) NSDate *endDate;
@property (nonatomic, readwrite, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation WADocumentStreamViewController

+ (WADocumentStreamViewController *)initWithDate:(NSDate *)date {

	WADocumentStreamViewController *vc = [[WADocumentStreamViewController alloc] init];
	if (vc) {
		NSCalendar *calendar = [NSCalendar currentCalendar];
		NSDateComponents *dateComponents = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:date];
		vc.startDate = [calendar dateFromComponents:dateComponents];
		[dateComponents setDay:1];
		[dateComponents setMonth:0];
		[dateComponents setYear:0];
		vc.endDate = [calendar dateByAddingComponents:dateComponents toDate:vc.startDate options:0];
	}
	return vc;

}

- (void)viewDidLoad {

	[super viewDidLoad];
	
	[self.collectionView registerClass:[WADocumentStreamViewCell class] forCellWithReuseIdentifier:kWADocumentStreamViewCellID];

	NSManagedObjectContext *context = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"WAFile" inManagedObjectContext:context];
	[request setEntity:entity];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(created > %@) AND (created <= %@)", self.startDate, self.endDate];
	[request setPredicate:predicate];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"created" ascending:YES];
	[request setSortDescriptors:@[sortDescriptor]];

	self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
	[self.fetchedResultsController performFetch:nil];

}

#pragma mark - NSFetchedResultsController delegates

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {

	NSLog(@"object:%@, indexPath:%@, type:%@, newIndexPath:%@", anObject, indexPath, type, newIndexPath);

}

#pragma mark - UICollectionView delegates

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

	return [self.fetchedResultsController.fetchedObjects count];

}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

	WADocumentStreamViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:kWADocumentStreamViewCellID forIndexPath:indexPath];

	NSArray *documents = self.fetchedResultsController.fetchedObjects;
	[cell.imageView irBind:@"image" toObject:documents[[indexPath row]] keyPath:@"smallThumbnailImage" options:@{kIRBindingsAssignOnMainThreadOption:(id)kCFBooleanTrue}];

	return cell;

}

@end
