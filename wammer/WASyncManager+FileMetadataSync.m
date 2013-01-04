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
#import <MagicalRecord.h>

@implementation WASyncManager (FileMetadataSync)

- (IRAsyncOperation *)fileMetadataSyncOperationPrototype {
  
  __weak WASyncManager *wSelf = self;
  
  return [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
    
    if (![wSelf canPerformMetaSync]) {
      callback(nil);
      return;
    }

    [wSelf beginPostponingSync];

    const NSUInteger MAX_FILEMETAS_COUNT = 20;
    WADataStore *ds = [WADataStore defaultStore];
    NSArray *files = [ds fetchFilesNeedingMetadataSyncUsingContext:[ds disposableMOC]];

    NSMutableArray *hiddenFiles = [NSMutableArray array];
    NSMutableArray *uploadFiles = [NSMutableArray array];
    for (WAFile *file in files) {
      if ([file.hidden isEqualToNumber:@YES]) {
        [hiddenFiles addObject:file];
      } else {
        [uploadFiles addObject:file];
      }
    }
    
    if ([hiddenFiles count]) {

      NSMutableArray *hiddenFileIdentifiers = [NSMutableArray array];
      for (WAFile *file in hiddenFiles) {
        [hiddenFileIdentifiers addObject:file.identifier];
      }

      IRAsyncOperation *operation = [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {

        [[WARemoteInterface sharedInterface] hideAttachments:hiddenFileIdentifiers onSuccess:^(NSArray *successIDs){

	NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
	context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"WAFile" inManagedObjectContext:context];
	[request setEntity:entity];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier IN %@", successIDs];
	[request setPredicate:predicate];
	
	NSError *error = nil;
	NSArray *files = [context executeFetchRequest:request error:&error];
	if (error) {
	  NSLog(@"Unable to fetch WAFiles in %@, error: %@", successIDs, error);
	} else {
	  for (WAFile *file in files) {
	    file.dirty = @NO;
	  }
	  if (![context save:&error]) {
	    NSLog(@"Unable to save WAFiles %@, error: %@", files, error);
	  }
	}

	callback(nil);

        } onFailure:^(NSError *error) {

	NSLog(@"Unable to hide attachments in %@, error: %@", hiddenFileIdentifiers, error);
	callback(error);

        }];

      } trampoline:^(IRAsyncOperationInvoker callback) {

        NSCParameterAssert(![NSThread isMainThread]);
        callback();

      } callback:^(id results) {

        // NO OP

      } callbackTrampoline:^(IRAsyncOperationInvoker callback) {

        NSCParameterAssert(![NSThread isMainThread]);
        callback();

      }];

      [wSelf.fileMetadataSyncOperationQueue addOperation:operation];

    }
    
    NSMutableArray *fileMetas = [NSMutableArray array];
    [uploadFiles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      
      WAFile *file = obj;
      NSCAssert(file.assetURL, @"Imported file should have its asset URL");

      NSURL *fileAssetURL = [NSURL URLWithString:file.assetURL];
      NSURL *ownURL = [[file objectID] URIRepresentation];

      IRAsyncBarrierOperation *operation = [IRAsyncBarrierOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
        
        [[WAAssetsLibraryManager defaultManager] assetForURL:fileAssetURL resultBlock:^(ALAsset *asset) {
	
	NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
	WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
	
	if (!asset) {
	  NSLog(@"Asset does not exist for WAFile %@, hide it.", file);
	  file.hidden = @YES;
	  file.dirty = @YES;
	  [context save:nil];
	  callback(nil);
	  return;
	}

	if ([file.dirty isEqualToNumber:(id)kCFBooleanTrue]) {
	  
	  NSMutableDictionary *meta = [NSMutableDictionary dictionary];
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
	    
	    [[WARemoteInterface sharedInterface] createAttachmentMetas:fileMetas onSuccess:^(NSArray *successIDs){
	      
	      NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
	      context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	      NSFetchRequest *request = [[NSFetchRequest alloc] init];
	      NSEntityDescription *entity = [NSEntityDescription entityForName:@"WAFile" inManagedObjectContext:context];
	      [request setEntity:entity];
	      NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier IN %@", successIDs];
	      [request setPredicate:predicate];
	      
	      NSError *error = nil;
	      NSArray *files = [context executeFetchRequest:request error:&error];
	      if (error) {
	        NSLog(@"Unable to fetch WAFiles in %@, error: %@", successIDs, error);
	      } else {
	        for (WAFile *file in files) {
		file.dirty = @NO;
	        }
	        if (![context save:&error]) {
		NSLog(@"Unable to save WAFiles %@, error: %@", files, error);
	        }
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
