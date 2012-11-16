//
//  WASyncManager+FileMetadataSync.m
//  wammer
//
//  Created by kchiu on 12/11/12.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WASyncManager+FileMetadataSync.h"
#import "WADataStore+WASyncManagerAdditions.h"
#import "WARemoteInterface.h"
#import "WAAssetsLibraryManager.h"
#import "WAAppDelegate_iOS.h"
#import "WADefines+iOS.h"
#import "WAFileExif+WAAdditions.h"

@implementation WASyncManager (FileMetadataSync)

- (IRAsyncOperation *)fileMetadataSyncOperation {

	__weak WASyncManager *wSelf = self;

	return [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {

		if ([(WAAppDelegate_iOS *)AppDelegate() photoImportManager].operationQueue.operationCount > 0) {
			callback(nil);
			return;
		}

		__block NSMutableArray *fileMetas = [@[] mutableCopy];
		const NSUInteger MAX_FILEMETAS_COUNT = 20;
		WADataStore *ds = [WADataStore defaultStore];
		NSArray *files = [ds fetchFilesNeedingMetadataSyncUsingContext:[ds disposableMOC]];
		[files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

			WAFile *file = obj;
			NSAssert(file.assetURL, @"Imported file should have its asset URL");

			[[WAAssetsLibraryManager defaultManager] assetForURL:[NSURL URLWithString:file.assetURL] resultBlock:^(ALAsset *asset) {
				
				NSURL *ownURL = [[file objectID] URIRepresentation];
				
				__block NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
					
					if ([operation isCancelled]) {
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
							meta[@"file_create_time"] = [[WADataStore defaultStore] ISO8601StringFromDate:file.timestamp];
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
								
							} onFailure:^(NSError *error) {
								NSLog(@"Unable to upload attachment metadata, error: %@", error);
							}];
							
							[fileMetas removeAllObjects];

							// slow down metadata uploading speed to avoid blocking other http requests
							[NSThread sleepForTimeInterval:3.0];
							
						}
					}
					
				}];
				
				[wSelf.fileMetadataSyncOperationQueue addOperation:operation];
				
			} failureBlock:^(NSError *error) {
				NSLog(@"Unable to load assets, error:%@", error);
			}];
			
		}];

		[wSelf.fileMetadataSyncOperationQueue addOperationWithBlock:^{
			callback(nil);
		}];

	} trampoline:^(IRAsyncOperationInvoker callback) {

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), callback);

	} callback:^(id results) {

//		NSLog(@"Attachment metadata upload finished");

	} callbackTrampoline:^(IRAsyncOperationInvoker callback) {

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), callback);

	}];

}

@end
