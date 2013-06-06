//
//  WAEventPhotoPickerDataSource.m
//  wammer
//
//  Created by Shen Steven on 5/13/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAEventPhotoPickerDataSource.h"
#import "WAAssetsLibraryManager.h"

@interface WAEventPhotoPickerDataSource ()
@property (nonatomic, copy) void (^completionHandler)(NSIndexSet *);
@property (nonatomic, strong) NSDate *lastLoadedDate;
@property (nonatomic, strong) NSMutableArray *photoGroups;
@end

#define EVENT_GROUPING_THRESHOLD (30 * 60)
#define BATCH_PROCESS_EVENTS 20
@implementation WAEventPhotoPickerDataSource

- (id) initWithPhotosLoadedUntil:(NSDate*)until completionHandler:(void(^)(NSIndexSet *changedSections))completionHandler {
  self = [super init];
  if (self) {
    self.photoGroups = [NSMutableArray array];
    [self loadMorePhotosSinceDate:[NSDate date] until:until];
    self.completionHandler = completionHandler;    
  }
  return self;
}

- (id) initWithCompletionHandler:(void(^)(NSIndexSet *changedSections))completionHandler {
  self = [super init];
  if (self) {
    self.photoGroups = [NSMutableArray array];
    [self loadMorePhotosSinceDate:[NSDate date] until:nil];
    self.completionHandler = completionHandler;
  }
  return self;
}

- (void) loadMorePhotosSinceDate:(NSDate*)date until:(NSDate*)until{
  __weak WAEventPhotoPickerDataSource *wSelf = self;
  __block NSUInteger processingEvents = 0;
  NSMutableIndexSet *changedIndexices = [NSMutableIndexSet indexSet];
  NSMutableArray *changedGroups = [NSMutableArray array];
  __block NSDate *currentProcessingDate = self.lastLoadedDate;
  
  [[WAAssetsLibraryManager defaultManager]
   enumerateSavedPhotosSince:date
   onProgess:^(NSArray *assets, NSDate *progressDate, BOOL *stop) {
     
     __block NSDate *previousDate = nil;
     NSMutableArray *photoList = [NSMutableArray array];
     [assets enumerateObjectsUsingBlock:^(ALAsset *asset, NSUInteger idx, BOOL *stop) {
       
       NSString *filename = [[asset defaultRepresentation] filename];
       NSRange found = [filename rangeOfString:@".PNG" options:NSCaseInsensitiveSearch];
       if (found.location != NSNotFound)
         return;
       
       if (!previousDate) {
         [photoList addObject:asset];
         previousDate = [asset valueForProperty:ALAssetPropertyDate];
       } else {
         
         NSDate *assetDate = [asset valueForProperty:ALAssetPropertyDate];
         NSTimeInterval assetInterval = [assetDate timeIntervalSince1970];
         NSTimeInterval previousInterval = [previousDate timeIntervalSince1970];
         if ((previousInterval - assetInterval) > EVENT_GROUPING_THRESHOLD) {
           
           previousDate = assetDate;
           [changedIndexices addIndex:(wSelf.photoGroups.count + changedGroups.count + processingEvents)];
           [changedGroups addObject:[photoList copy]];
           processingEvents ++;
           
           [photoList removeAllObjects];
           [photoList addObject:asset];
           
         } else {
           
           previousDate = assetDate;
           [photoList addObject:asset];
           
         }
       }
     }];
     if (photoList.count) {
       [changedIndexices addIndex:(wSelf.photoGroups.count + changedGroups.count + processingEvents)];
       [changedGroups addObject:[photoList copy]];
       processingEvents ++;
       
       [photoList removeAllObjects];

     }
     
     if (!until) {
       if (processingEvents > BATCH_PROCESS_EVENTS) {
         currentProcessingDate = progressDate;
         *stop = YES;
         return;
       }
     } else {
       if ([previousDate compare:until] != NSOrderedDescending) {
         currentProcessingDate = progressDate;
         *stop = YES;
         return;
       }
     }
     
   } onComplete:^(NSDate *progressDate){
     
     if (wSelf.completionHandler) {

       if (!wSelf.lastLoadedDate || ![wSelf.lastLoadedDate isEqualToDate:currentProcessingDate]) {
         [wSelf.photoGroups addObjectsFromArray:changedGroups];
         wSelf.lastLoadedDate = progressDate;
         wSelf.completionHandler([changedIndexices copy]);
       } else {
         wSelf.completionHandler(nil);
       }
     }
     
   } onFailure:^(NSError *error) {
     
   }];

}

- (NSUInteger) numberOfEvents {
  
  return self.photoGroups.count;
  
}

- (NSUInteger) numberOfPhotosInEvent:(NSUInteger)eventSection {
  return [self.photoGroups[eventSection] count];
}

- (NSArray*) photosInEvent:(NSUInteger)eventSection {
  return self.photoGroups[eventSection];
}

- (ALAsset *) photoAtIndexPath:(NSIndexPath*)indexPath {
  return self.photoGroups[indexPath.section][indexPath.row];
}

- (BOOL) loadMoreEvents {
  [self loadMorePhotosSinceDate:self.lastLoadedDate until:nil];
  return YES;
}

@end
