//
//  WASyncManager+PhotoImport.m
//  wammer
//
//  Created by kchiu on 12/12/24.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WASyncManager+PhotoImport.h"
#import "IRRecurrenceMachine.h"
#import "WAAssetsLibraryManager.h"
#import "WAFileExif+WAAdditions.h"
#import "WAPhotoDay.h"
#import "WADefines.h"
#import "NSDate+WAAdditions.h"

#import <MobileCoreServices/MobileCoreServices.h>

@implementation WASyncManager (PhotoImport)

- (IRAsyncOperation *)photoImportOperationPrototype {
  
  __weak WASyncManager *wSelf = self;
  
  return [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
    
    if (![wSelf canPerformPhotoImport]) {
      callback(nil);
      return;
    }
    
    [wSelf beginPostponingSync];
    
    NSDate *importTime = [NSDate date];
    WADataStore *ds = [WADataStore defaultStore];
    
    __block NSUInteger filesCount = 0;
    [[WAAssetsLibraryManager defaultManager] enumerateSavedPhotosSince:nil onProgess:^(NSArray *assets, NSDate *progressDate, BOOL *stop) {
      
      if (![assets count]) {
        return;
      }
      
      filesCount += [assets count];
      
      __block NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        
        if ([operation isCancelled]) {
          NSLog(@"A photo import operation was canceled");
          return;
        }
        
        NSManagedObjectContext *context = [ds disposableMOC];
        WAArticle *article = [WAArticle objectInsertingIntoContext:context withRemoteDictionary:@{}];
        [assets enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          ALAsset *asset = (ALAsset *)obj;
          if (![[asset defaultRepresentation] url]) {// asset no longer exist
            NSLog(@"asset no longer exist.");
            return;
          }
          
          @autoreleasepool {
            
            WAFile *file = (WAFile *)[WAFile objectInsertingIntoContext:context withRemoteDictionary:@{}];
            CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
            if (theUUID)
              file.identifier = [((__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, theUUID)) lowercaseString];
            CFRelease(theUUID);
            file.dirty = (id)kCFBooleanTrue;
            
            [[article mutableOrderedSetValueForKey:@"files"] addObject:file];
            
            UIImage *extraSmallThumbnailImage = [UIImage imageWithCGImage:[asset thumbnail]];
            file.extraSmallThumbnailFilePath = [[[WADataStore defaultStore] persistentFileURLForData:UIImageJPEGRepresentation(extraSmallThumbnailImage, 0.85f) extension:@"jpeg"] path];
            
            file.assetURL = [[[asset defaultRepresentation] url] absoluteString];
            file.resourceType = (NSString *)kUTTypeImage;
            file.timestamp = [asset valueForProperty:ALAssetPropertyDate];
            file.created = file.timestamp;
            file.importTime = importTime;
            
            WAFileExif *exif = (WAFileExif *)[WAFileExif objectInsertingIntoContext:context withRemoteDictionary:@{}];
            NSDictionary *metadata = [[asset defaultRepresentation] metadata];
            [exif initWithExif:metadata[@"{Exif}"] tiff:metadata[@"{TIFF}"] gps:metadata[@"{GPS}"]];
            
            file.exif = exif;
            
            WAPhotoDay *day = (WAPhotoDay *)[WAPhotoDay objectInsertingIntoContext:context withRemoteDictionary:@{}];
            day.day = [file.created dayBegin];
            file.photoDay = day;
            
            if (!article.creationDate) {
              article.creationDate = file.timestamp;
            } else {
              if ([file.timestamp compare:article.creationDate] == NSOrderedDescending) {
                article.creationDate = file.timestamp;
              }
            }
            
            wSelf.importedFilesCount += 1;
            
          }
          
        }];
        
        article.event = @NO;
        article.draft = (id)kCFBooleanFalse;
        CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
        if (theUUID)
          article.identifier = [((__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, theUUID)) lowercaseString];
        CFRelease(theUUID);
        article.dirty = (id)kCFBooleanTrue;
        article.creationDeviceName = [UIDevice currentDevice].name;
        
        NSError *savingError = nil;
        if ([context save:&savingError]) {
          [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[GAI sharedInstance].defaultTracker trackEventWithCategory:@"Application" withAction:@"ImportFromCameraRol" withLabel:@"Photos" withValue:@([article.files count])];
          }];
        } else {
          NSLog(@"Error saving: %s %@", __PRETTY_FUNCTION__, savingError);
        }
 
        return;
        
      }];
      
      [wSelf.photoImportOperationQueue addOperation:operation];
      
    } onComplete:^(NSDate *progressDate){
      
      NSCAssert(wSelf.needingImportFilesCount == 0, @"file import count should be reset before starting photo import");
      wSelf.needingImportFilesCount = filesCount; // display status bar via KVO
      
      NSBlockOperation *tailOp = [NSBlockOperation blockOperationWithBlock:^{
        [wSelf endPostponingSync];
        callback(nil);
      }];
      for (NSOperation *operation in wSelf.photoImportOperationQueue.operations) {
        [tailOp addDependency:operation];
      }
      [wSelf.photoImportOperationQueue addOperation:tailOp];
      
    } onFailure:^(NSError *error) {
      
      NSCAssert(wSelf.needingImportFilesCount == 0, @"file import count should be reset before starting photo import");
      wSelf.needingImportFilesCount = filesCount; // display status bar via KVO
      
      NSBlockOperation *tailOp = [NSBlockOperation blockOperationWithBlock:^{
        [wSelf endPostponingSync];
        callback(error);
      }];
      for (NSOperation *operation in wSelf.photoImportOperationQueue.operations) {
        [tailOp addDependency:operation];
      }
      [wSelf.photoImportOperationQueue addOperation:tailOp];
      
      NSLog(@"Unable to enumerate saved photos: %s %@", __PRETTY_FUNCTION__, error);
      
    }];
    
  } trampoline:^(IRAsyncOperationInvoker callback) {
    
    NSCAssert(![NSThread isMainThread], @"should run in background");
    callback();
    
  } callback:^(id results) {
    
    // NO OP
    
  } callbackTrampoline:^(IRAsyncOperationInvoker callback) {
    
    NSCAssert(![NSThread isMainThread], @"should run in background");
    callback();
    
  }];
  
}

- (BOOL)canPerformPhotoImport {
  
  if ([[NSUserDefaults standardUserDefaults] objectForKey:kWAFirstUseVisited]!=nil &&  ![[NSUserDefaults standardUserDefaults] boolForKey:kWAFirstUseVisited])
    return NO;// don't import photos before user has visite photo import setting in first use
  
  if (![[NSUserDefaults standardUserDefaults] boolForKey:kWAPhotoImportEnabled]) {
    return NO;
  }
  
  return YES;
  
}

@end
