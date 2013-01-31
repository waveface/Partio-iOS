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
#import "WACalendarPickerViewController.h"

@interface WADocumentStreamViewController ()

@property (nonatomic, readwrite, strong) NSDate *currentDate;
@property (nonatomic, readwrite, strong) NSMutableArray *documents;
@property (nonatomic, readwrite, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation WADocumentStreamViewController

+ (NSFetchRequest *)fetchRequestForFileAccessLogsOnDate:(NSDate *)date {

  NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"WAFileAccessLog"];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"day.day == %@", date];
  [request setPredicate:predicate];
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"accessTime" ascending:NO];
  [request setSortDescriptors:@[sortDescriptor]];
  [request setRelationshipKeyPathsForPrefetching:@[@"day", @"file", @"file.pageElements"]];

  return request;

}

- (id)initWithDate:(NSDate *)date {
  
  self = [super init];
  if (self) {
    
    self.currentDate = date;
    
    NSManagedObjectContext *context = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
    NSFetchRequest *request = [[self class] fetchRequestForFileAccessLogsOnDate:self.currentDate];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    
    self.fetchedResultsController.delegate = self;
    
    [self.fetchedResultsController performFetch:nil];
    
    self.documents = [NSMutableArray array];
    NSMutableDictionary *filePathAccessLogs = [NSMutableDictionary dictionary];
    [self.fetchedResultsController.fetchedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      WAFileAccessLog *accessLog = (WAFileAccessLog *)obj;
      if (!filePathAccessLogs[accessLog.filePath]) {
        filePathAccessLogs[accessLog.filePath] = accessLog;
        [self.documents addObject:accessLog.file];
      }
    }];
    
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

- (NSUInteger) supportedInterfaceOrientations {
  
  return [self.parentViewController supportedInterfaceOrientations];
  
}

- (BOOL)shouldAutorotate {
  
  return YES;
  
}

#pragma mark - NSFetchedResultsController delegates

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
  
  switch (type) {
    case NSFetchedResultsChangeMove: // don't know why, but sometimes the type is NSFetchedResultsChangeMove
    case NSFetchedResultsChangeInsert: {
      NSUInteger oldIndex = [self.documents indexOfObject:[anObject file]];
      
      NSMutableDictionary *filePathAccessLogs = [NSMutableDictionary dictionary];
      [self.fetchedResultsController.fetchedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([anObject isEqual:obj]) {
	*stop = YES;
	return;
        }
        if ([[anObject accessTime] compare:[obj accessTime]] == NSOrderedDescending) {
	*stop = YES;
	return;
        }
        if (!filePathAccessLogs[[obj filePath]]) {
	filePathAccessLogs[[obj filePath]] = obj;
        }
      }];
      
      NSUInteger newIndex = [filePathAccessLogs count];
      
      if (oldIndex == NSNotFound) {
        [self.documents insertObject:[anObject file] atIndex:newIndex];
        if ([self.documents count] == 1) {
	// call reloadData for the first cell, ref: http://stackoverflow.com/questions/12611292/uicollectionview-assertion-failure
	[self.collectionView reloadData];
        } else {
	[self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:newIndex inSection:0]]];
        }
      } else {
        [self.documents removeObject:[anObject file]];
        [self.documents insertObject:[anObject file] atIndex:newIndex];
        [self.collectionView moveItemAtIndexPath:[NSIndexPath indexPathForRow:oldIndex inSection:0] toIndexPath:[NSIndexPath indexPathForRow:newIndex inSection:0]];
      }
    }
    case NSFetchedResultsChangeUpdate:
      // update shouldn't change the item sequence
      break;
    case NSFetchedResultsChangeDelete:
      NSAssert(NO, @"File access logs should never been purged");
      break;
    default:
      break;
  }
  
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
  cell.fileNameLabel.text = document.remoteFileName;
  
  if ([document.pageElements count]) {
    WAFilePageElement *coverPage = document.pageElements[0];
    cell.pageElement = coverPage;
    [[[self class] sharedImageDisplayQueue] addOperationWithBlock:^{
      [coverPage irObserve:@"thumbnailImage" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:&kWADocumentStreamViewCellKVOContext withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
	cell.imageView.image = toValue;
        }];
      }];
    }];
  }
  
  return cell;
  
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  
  WAFile *document = self.documents[indexPath.row];
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
