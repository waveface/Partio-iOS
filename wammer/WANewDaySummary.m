//
//  WANewDaySummary.m
//  wammer
//
//  Created by kchiu on 13/2/10.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WANewDaySummary.h"
#import "WADataStore.h"
#import "WAPhotoStreamViewController.h"
#import "WADocumentStreamViewController.h"
#import "WAWebStreamViewController.h"
#import "WAFileAccessLog.h"
#import "WANewDayEvent.h"

@implementation WANewDaySummary

- (NSString *)description {
  return [NSString stringWithFormat:@"%@, {%d Events, %d Photos, %d Documents, %d WebPages}", _date, _numOfEvents, _numOfPhotos, _numOfDocuments, _numOfWebpages];
}

- (void)reloadData {
  
  NSAssert(self.date, @"Date should be initialized before reloading data.");

  __weak WANewDaySummary *wSelf = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

    WADataStore *ds = [WADataStore defaultStore];
    NSManagedObjectContext *moc = [ds disposableMOC];

    NSFetchRequest *articlesFetchRequest = [ds newFetchRequestForArticlesOnDate:wSelf.date];
    wSelf.numOfEvents = [moc countForFetchRequest:articlesFetchRequest error:nil];

    NSFetchRequest *photosFetchRequest = [WAPhotoStreamViewController fetchRequestForPhotosOnDate:wSelf.date];
    wSelf.numOfPhotos = [moc countForFetchRequest:photosFetchRequest error:nil];
    
    NSFetchRequest *documentAccessLogsFetchRequest = [WADocumentStreamViewController fetchRequestForFileAccessLogsOnDate:wSelf.date];
    NSArray *documentAccessLogs = [moc executeFetchRequest:documentAccessLogsFetchRequest error:nil];
    NSMutableSet *documentFilePathSet = [NSMutableSet set];
    for (WAFileAccessLog *accessLog in documentAccessLogs) {
      [documentFilePathSet addObject:accessLog.filePath];
    }
    wSelf.numOfDocuments = [documentFilePathSet count];
    
    NSFetchRequest *webpageAccessLogsFetchRequest = [WAWebStreamViewController fetchRequestForWebpageAccessLogsOnDate:wSelf.date];
    NSArray *webpageAccessLogs = [moc executeFetchRequest:webpageAccessLogsFetchRequest error:nil];
    NSMutableSet *webpageFileIdentifierSet = [NSMutableSet set];
    for (WAFileAccessLog *accessLog in webpageAccessLogs) {
      [webpageFileIdentifierSet addObject:accessLog.file.identifier];
    }
    wSelf.numOfWebpages = [webpageFileIdentifierSet count];

  });  

}

@end
