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
#import "NSDate+WAAdditions.h"
#import "WADayHeaderView.h"
#import "WAFilePageElement+WAAdditions.h"
#import "WAGalleryViewController.h"
#import "WAFileAccessLog.h"
#import "WADocumentPreviewController.h"

@interface WADocumentStreamViewController ()

@property (nonatomic, readwrite, strong) NSDate *currentDate;
@property (nonatomic, readwrite, strong) NSMutableArray *documents;
@property (nonatomic, readwrite, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation WADocumentStreamViewController

- (id)initWithDate:(NSDate *)date {

	self = [super init];
	if (self) {

		self.currentDate = date;

		NSManagedObjectContext *context = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"WAFileAccessLog" inManagedObjectContext:context];
		[request setEntity:entity];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"day.day == %@", self.currentDate];
		[request setPredicate:predicate];
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"accessTime" ascending:YES];
		[request setSortDescriptors:@[sortDescriptor]];
		[request setRelationshipKeyPathsForPrefetching:@[@"file"]];
		[request setRelationshipKeyPathsForPrefetching:@[@"day"]];

		self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];

		[self.fetchedResultsController performFetch:nil];

		NSMutableDictionary *filePathAccessLogs = [NSMutableDictionary dictionary];
		[self.fetchedResultsController.fetchedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			WAFileAccessLog *accessLog = (WAFileAccessLog *)obj;
			WAFileAccessLog *currentAccessLog = filePathAccessLogs[accessLog.filePath];
			if (currentAccessLog) {
				if ([accessLog.accessTime compare:currentAccessLog.accessTime] == NSOrderedDescending) {
					filePathAccessLogs[accessLog.filePath] = accessLog;
				}
			} else {
				filePathAccessLogs[accessLog.filePath] = accessLog;
			}
		}];

		self.documents = [NSMutableArray array];
		for (WAFileAccessLog *accessLog in [filePathAccessLogs allValues]) {
			[self.documents addObject:accessLog.file];
		}

	}
	return self;

}

- (void)viewDidLoad {

	[super viewDidLoad];
	
	[self.collectionView registerClass:[WADocumentStreamViewCell class] forCellWithReuseIdentifier:kWADocumentStreamViewCellID];
	[self.collectionView registerNib:[UINib nibWithNibName:@"WADayHeaderView" bundle:nil]
				forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
							 withReuseIdentifier:kWADayHeaderViewID];

}

#pragma mark - NSFetchedResultsController delegates

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {

	// TODO: monitor changes
	NSLog(@"object:%@, indexPath:%@, type:%@, newIndexPath:%@", anObject, indexPath, type, newIndexPath);

}

#pragma mark - UICollectionView delegates

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

	return [self.documents count];

}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {

	WADayHeaderView *headerView = [self.collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kWADayHeaderViewID forIndexPath:indexPath];

	headerView.dayLabel.text = [self.currentDate dayString];
	headerView.monthLabel.text = [[self.currentDate localizedMonthShortString] uppercaseString];
	headerView.wdayLabel.text = [[self.currentDate localizedWeekDayFullString] uppercaseString];
	headerView.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1];

	return headerView;

}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

	WADocumentStreamViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:kWADocumentStreamViewCellID forIndexPath:indexPath];

	WAFile *document = self.documents[[indexPath row]];

	[[[self class] sharedImageDisplayQueue] addOperationWithBlock:^{
		cell.pageElement = document.pageElements[0];
		[document.pageElements[0] irObserve:@"thumbnailImage" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:&kWADocumentStreamViewCellKVOContext withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				cell.imageView.image = toValue;
			}];
		}];
	}];

	cell.fileNameLabel.text = document.remoteFileName;

	return cell;

}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

	WAFile *document = self.documents[indexPath.row];
//	WAGalleryViewController *galleryVC = [[WAGalleryViewController alloc] initWithImageFiles:[document.pageElements array] atIndex:0];
//	
//	[self.navigationController pushViewController:galleryVC animated:YES];

	WADocumentPreviewController *previewController = [[WADocumentPreviewController alloc] initWithFile:document];
	
	[self.navigationController pushViewController:previewController animated:YES];


}

+ (NSOperationQueue *)sharedImageDisplayQueue {

	static NSOperationQueue *queue;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:1];
	});

	return queue;

}

@end
