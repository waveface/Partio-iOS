//
//  WASyncManager+FileMetadataSync.m
//  wammer
//
//  Created by kchiu on 12/11/12.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WASyncManager+FileMetadataSync.h"
#import "WADataStore+WASyncManagerAdditions.h"
#import "IRRecurrenceMachine.h"
#import "WARemoteInterface.h"
#import "WAAssetsLibraryManager.h"
#import "WAAppDelegate_iOS.h"
#import "WADefines+iOS.h"
#import "WAFileExif+WAAdditions.h"
#import <NSDate+SSToolkitAdditions.h>
#import "WADefines.h"

@implementation WASyncManager (FileMetadataSync)

- (IRAsyncOperation *)fileMetadataSyncOperationPrototype {
  
  __weak WASyncManager *wSelf = self;
  
  return [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
    
    if (![wSelf canPerformMetaSync]) {
      callback(nil);
      return;
    }

    [wSelf beginPostponingSync];

    __block NSMutableArray *fileMetas = [@[] mutableCopy];
    const NSUInteger MAX_FILEMETAS_COUNT = 20;
    WADataStore *ds = [WADataStore defaultStore];
    NSArray *files = [ds fetchFilesNeedingMetadataSyncUsingContext:[ds disposableMOC]];
    [files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      
      WAFile *file = obj;
      NSCAssert(file.assetURL, @"Imported file should have its asset URL");

      NSURL *fileAssetURL = [NSURL URLWithString:file.assetURL];
      NSURL *ownURL = [[file objectID] URIRepresentation];

      IRAsyncBarrierOperation *operation = [IRAsyncBarrierOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
        
        [[WAAssetsLibraryManager defaultManager] assetForURL:fileAssetURL resultBlock:^(ALAsset *asset) {
	
	// TODO: hide attachments if user has delete them from camera roll
	if (!asset) {
	  callback(nil);
	  return;
	}

	WAFile *file = (WAFile *)[[[WADataStore defaultStore] disposableMOC] irManagedObjectForURI:ownURL];

	if ([file.dirty isEqualToNumber:(id)kCFBooleanTrue]) {
	  
	  NSMutableDictionary *meta = [@{} mutableCopy];
	  meta[@"file_name"] = [[asset defaultRepresentation] filename];
	  meta[@"type"] = @"image";
	  meta[@"timezone"] = [NSString stringWithFormat:@"%d", [[NSTimeZone localTimeZone] secondsFromGMT]/60];
	  if (file.identifier) {
	    meta[@"object_id"] = file.identifier;
	  }
	  if (file.timestamp) {
	    meta[@"file_create_time"] = [file.timestamp ISO8601String];
	  }
	  if (file.exif) {
	    meta[@"exif"] = [file.exif remoteRepresentation];
	  }
	  
	  [fileMetas addObject:meta];

	  if ([fileMetas count] == MAX_FILEMETAS_COUNT || idx == [files count]-1) {
	    
	    [[WARemoteInterface sharedInterface] createAttachmentMetas:fileMetas onSuccess:^{
	      
	      NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
	      context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	      WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
	      file.dirty = (id)kCFBooleanFalse;
	      
	      NSError *error = nil;
	      [context save:&error];
	      if (error) {
	        NSLog(@"Unable to save file: %@, error: %@", file, error);
	      }
	      
	      callback(nil);
	      
	    } onFailure:^(NSError *error) {
	      
	      NSLog(@"Unable to upload attachment metadata, error: %@", error);
	      
	      callback(error);
	      
	    }];
	    
	    [fileMetas removeAllObjects];
	    
	    return;
	    
	  }
	  
	}
	
	callback(nil);
	
        } failureBlock:^(NSError *error) {
	
	NSLog(@"Unable to load assets, error:%@", error);
	
	callback(error);
	
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
      
      [wSelf.fileMetadataSyncOperationQueue addOperation:operation];
      
    }];

    NSBlockOperation *tailOp = [NSBlockOperation blockOperationWithBlock:^{
      [wSelf endPostponingSync];
    }];

    for (NSOperation *operation in wSelf.fileMetadataSyncOperationQueue.operations) {
      [tailOp addDependency:operation];
    }

    [wSelf.fileMetadataSyncOperationQueue addOperation:tailOp];

    callback(nil);
    
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

- (BOOL)canPerformMetaSync {

  if (![[NSUserDefaults standardUserDefaults] boolForKey:kWAPhotoImportEnabled]) {
    return NO;
  }
  
  WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
  if (!ri.userToken) {
    return NO;
  }
  
  return YES;

}

@end
