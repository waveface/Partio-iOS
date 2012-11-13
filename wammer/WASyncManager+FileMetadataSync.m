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

@implementation WASyncManager (FileMetadataSync)

- (IRAsyncOperation *)fileMetadataSyncOperation {

	__weak WASyncManager *wSelf = self;

	return [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
	
		WADataStore *ds = [WADataStore defaultStore];
		NSArray *files = [ds fetchFilesNeedingMetadataSyncUsingContext:[ds disposableMOC]];
		for (WAFile *file in files) {

			if (file.assetURL) {

				[[WAAssetsLibraryManager defaultManager] assetForURL:[NSURL URLWithString:file.assetURL] resultBlock:^(ALAsset *asset) {

					NSURL *ownURL = [[file objectID] URIRepresentation];

					__block NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{

						if ([operation isCancelled]) {
							return;
						}

						WAFile *file = (WAFile *)[[[WADataStore defaultStore] disposableMOC] irManagedObjectForURI:ownURL];
						if ([file.dirty isEqualToNumber:(id)kCFBooleanTrue]) {

							NSMutableDictionary *options = [@{kWARemoteAttachmentType: [NSNumber numberWithUnsignedInteger:WARemoteAttachmentImageType]} mutableCopy];
							
							if (file.identifier) {
								options[kWARemoteAttachmentUpdatedObjectIdentifier] = file.identifier;
							}
							if (file.timestamp) {
								options[kWARemoteAttachmentCreateTime] = file.timestamp;
							}
							if (file.exif) {
								options[kWARemoteAttachmentExif] = file.exif;
							}
							
							[[WARemoteInterface sharedInterface] createAttachmentWithName:[[asset defaultRepresentation] filename] options:options onSuccess:^{

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

						}

					}];

					[wSelf.fileMetadataSyncOperationQueue addOperation:operation];
					
				} failureBlock:^(NSError *error) {
					NSLog(@"Unable to load assets, error:%@", error);
				}];

			} else {
				NSLog(@"File %@ does not have assetURL", file);
			}

		}

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
