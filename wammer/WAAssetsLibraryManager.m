//
//  WAAssetsLibraryManager.m
//  wammer
//
//  Created by kchiu on 12/9/3.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAAssetsLibraryManager.h"
#import "WADataStore.h"

@interface NSDate (WAAssetsLibraryManager)

- (NSDate *) laterMidnight;
- (NSDate *) earlyMorning;

@end

@implementation NSDate (WAAssetsLibraryManager)

- (NSDate *)laterMidnight {
  
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDateComponents *components = [gregorian components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:self];
  const NSTimeInterval dayTimeInterval = 24 * 60 * 60;
  return [[gregorian dateFromComponents:components] dateByAddingTimeInterval:dayTimeInterval];
  
}

- (NSDate *)earlyMorning {

  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDateComponents *components = [gregorian components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:self];
  return [gregorian dateFromComponents:components];
  
}

@end


@implementation WAAssetsLibraryManager

+ (WAAssetsLibraryManager *) defaultManager {
  
  static WAAssetsLibraryManager *returnedManager = nil;
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
    
    returnedManager = [[self alloc] init];
    
  });
  
  return returnedManager;
  
}

- (id)init {
  
  self = [super init];
  
  if (self) {
    
    self.assetsLibrary = [[ALAssetsLibrary alloc] init];
    
  }
  
  return self;
  
}

- (void)assetForURL:(NSURL *)assetURL resultBlock:(ALAssetsLibraryAssetForURLResultBlock)resultBlock failureBlock:(ALAssetsLibraryAccessFailureBlock)failureBlock {
  
  [self.assetsLibrary assetForURL:assetURL resultBlock:resultBlock failureBlock:failureBlock];
  
}

- (void)writeImageToSavedPhotosAlbum:(CGImageRef)imageRef orientation:(ALAssetOrientation)orientation completionBlock:(ALAssetsLibraryWriteImageCompletionBlock)completionBlock {
  
  [self.assetsLibrary writeImageToSavedPhotosAlbum:imageRef orientation:orientation completionBlock:completionBlock];
  
}

- (void)retrieveTimeSortedPhotosWhenComplete:(void (^)(NSArray *result))onCompleteBlock onFailure:(void (^)(NSError *))onFailureBlock {
  NSMutableArray *allAssets = [NSMutableArray array];
  
  [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
    
    if (group) {
      
      [group setAssetsFilter:[ALAssetsFilter allPhotos]];
      
      // sorting all photos in camera roll by photo creation date
      [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (result) {
          NSUInteger indexToInsert = [allAssets indexOfObject:result inSortedRange:NSMakeRange(0, [allAssets count]) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(ALAsset *asset1, ALAsset *asset2) {
            return [[asset2 valueForProperty:ALAssetPropertyDate] compare:[asset1 valueForProperty:ALAssetPropertyDate]];
          }];
          [allAssets insertObject:result atIndex:indexToInsert];
        }
      }];
      
    } else {
      
      onCompleteBlock([NSArray arrayWithArray:allAssets]);
      
    }
    
  } failureBlock:^(NSError *error) {
    
    onFailureBlock(error);
    
  }];

}

- (void)enumerateSavedPhotosSince:(NSDate *)sinceDate onProgess:(void (^)(NSArray *, NSDate *, BOOL *stop))onProgressBlock onComplete:(void (^)(NSDate *))onCompleteBlock onFailure:(void (^)(NSError *))onFailureBlock {
  
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSInteger comps = (NSSecondCalendarUnit|NSMinuteCalendarUnit|NSHourCalendarUnit|NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit);
  if (sinceDate) {
    NSDateComponents *sinceDateComponents = [calendar components:comps fromDate:sinceDate];
    sinceDate = [calendar dateFromComponents:sinceDateComponents];
  }
  
  __block NSMutableArray *insertedAssets = [[NSMutableArray alloc] init];
  __block NSDate *midnight = sinceDate ? [sinceDate earlyMorning] : nil;
  
  [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
    
    if (group) {
      
      NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
      NSArray *importedFiles = [[WADataStore defaultStore] fetchImportedFiles:context];
      NSMutableSet *importedFileAssetURLs = [NSMutableSet set];
      for (WAFile *file in importedFiles) {
        [importedFileAssetURLs addObject:file.assetURL];
      }

      [group setAssetsFilter:[ALAssetsFilter allPhotos]];

      // sorting all photos in camera roll by photo creation date
      NSMutableArray *allAssets = [NSMutableArray array];
      [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (result) {
          NSUInteger indexToInsert = [allAssets indexOfObject:result inSortedRange:NSMakeRange(0, [allAssets count]) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(ALAsset *asset1, ALAsset *asset2) {
            return [[asset2 valueForProperty:ALAssetPropertyDate] compare:[asset1 valueForProperty:ALAssetPropertyDate]];
          }];
          [allAssets insertObject:result atIndex:indexToInsert];
        }
      }];

      [allAssets enumerateObjectsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        
        if (result) {
          
          NSDate *assetDate = [result valueForProperty:ALAssetPropertyDate];
          NSDateComponents *assetDateComponents = [calendar components:comps fromDate:assetDate];
          assetDate = [calendar dateFromComponents:assetDateComponents];
          if (sinceDate && ([assetDate compare:sinceDate] != NSOrderedAscending)) {
            return;
          }
          
          if (midnight) {
	  
            if ([assetDate compare:midnight] != NSOrderedDescending) {
	    
              NSArray *assets = [insertedAssets copy];
              BOOL stopCallback = NO;
              onProgressBlock(assets, midnight, &stopCallback);
              [insertedAssets removeAllObjects];
              if (stopCallback) {
                *stop = YES;
                onCompleteBlock(midnight);
                return;
              }
              midnight = [assetDate earlyMorning];
              
            }
            
          } else {
            
            midnight = [assetDate earlyMorning];
            
          }
          
          [insertedAssets addObject:result];
	
        }
        
        if (index == [allAssets count] - 1) {

          NSArray *assets = [insertedAssets copy];
          BOOL stop = NO;
          onProgressBlock(assets, midnight, &stop);
          [insertedAssets removeAllObjects];
          if (stop) {
            onCompleteBlock(midnight);
            return;
          }

        }
        
      }];
      
    } else {
      
      onCompleteBlock(midnight);
      
    }
    
  } failureBlock:^(NSError *error) {
    
    onFailureBlock(error);
    
  }];
  
}

@end