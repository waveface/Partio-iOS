//
//  WARemoteInterface+Attachments.m
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface+Attachments.h"
#import "WADataStore.h"

#import "IRWebAPIEngine+FormMultipart.h"
#import "WAAssetsLibraryManager.h"
#import <AssetsLibrary+IRAdditions.h>

NSString * const kWARemoteAttachmentType = @"WARemoteAttachmentType";
NSString * const kWARemoteAttachmentTitle = @"WARemoteAttachmentTitle";
NSString * const kWARemoteAttachmentDescription = @"WARemoteAttachmentDescription";
NSString * const kWARemoteAttachmentRepresentingImageURL = @"WARemoteAttachmentRepresentingImageURL";
NSString * const kWARemoteAttachmentUpdatedObjectIdentifier = @"WARemoteAttachmentUpdatedObjectIdentifier";
NSString * const kWARemoteAttachmentSubtype = @"kWARemoteAttachmentDestinationImageType";
NSString * const WARemoteAttachmentOriginalSubtype = @"origin";
NSString * const WARemoteAttachmentLargeSubtype = @"large";
NSString * const WARemoteAttachmentMediumSubtype = @"medium";
NSString * const WARemoteAttachmentSmallSubtype = @"small";


@implementation WARemoteInterface (Attachments)

- (void)createAttachmentWithFile:(NSURL *)aFileURL group:(NSString *)aGroupIdentifier options:(NSDictionary *)options onSuccess:(void (^)(NSString *))successBlock onFailure:(void (^)(NSError *))failureBlock {

	if ([aFileURL isFileURL]) {

		NSURL *copiedFileURL = [[WADataStore defaultStore] persistentFileURLForFileAtURL:aFileURL];
		[self createAttachmentWithCopiedFile:copiedFileURL group:aGroupIdentifier options:options onSuccess:successBlock onFailure:failureBlock];

	} else {

		[[WAAssetsLibraryManager defaultManager] assetForURL:aFileURL resultBlock:^(ALAsset *asset) {

			NSURL *copiedFileURL = [[WADataStore defaultStore] persistentFileURLForData:UIImageJPEGRepresentation([[asset defaultRepresentation] irImage], 0.85f) extension:@"jpeg"];
			[self createAttachmentWithCopiedFile:copiedFileURL group:aGroupIdentifier options:options onSuccess:successBlock onFailure:failureBlock];

		} failureBlock:^(NSError *error) {

			failureBlock(error);

		}];

	}

}

- (void) createAttachmentWithCopiedFile:(NSURL *)aCopiedFileURL group:(NSString *)aGroupIdentifier options:(NSDictionary *)options onSuccess:(void(^)(NSString *attachmentIdentifier))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSParameterAssert([aCopiedFileURL isFileURL] && [[NSFileManager defaultManager] fileExistsAtPath:[aCopiedFileURL path]]);
	NSParameterAssert([[aCopiedFileURL pathExtension] length]);
	NSParameterAssert(aGroupIdentifier);
		
	NSMutableDictionary *mergedOptions = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithUnsignedInteger:WARemoteAttachmentUnknownType], kWARemoteAttachmentType,
		WARemoteAttachmentOriginalSubtype, kWARemoteAttachmentSubtype,
	nil];
	
	[mergedOptions addEntriesFromDictionary:options];
	
	
	WARemoteAttachmentType type = [[mergedOptions objectForKey:kWARemoteAttachmentType] unsignedIntegerValue];
	WARemoteAttachmentSubtype subtype = [mergedOptions objectForKey:kWARemoteAttachmentSubtype];
	NSString *title = [mergedOptions objectForKey:kWARemoteAttachmentTitle];
	NSString *description = [mergedOptions objectForKey:kWARemoteAttachmentDescription];
	NSURL *proxyImage = [mergedOptions objectForKey:kWARemoteAttachmentRepresentingImageURL];
	NSString *updatedObjectID = [mergedOptions objectForKey:kWARemoteAttachmentUpdatedObjectIdentifier];
	
	if (type == WARemoteAttachmentUnknownType) {
	
		//	Time for some inference
		
		NSString *pathExtension = [aCopiedFileURL pathExtension];
		BOOL fileIsImage = NO;
		if (pathExtension) {
			CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)pathExtension, kUTTypeItem);
			if (fileUTI) {
				fileIsImage = UTTypeConformsTo(fileUTI, kUTTypeImage);
				CFRelease(fileUTI);
			}
		}
		
		if (fileIsImage) {
			type = WARemoteAttachmentImageType;
		} else {
			type = WARemoteAttachmentDocumentType;
		}
	
	}
	
	
	NSMutableDictionary *sentRemoteOptions = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		aCopiedFileURL, @"file",
		aGroupIdentifier, @"group_id",
	nil];
	
	switch (type) {
		case WARemoteAttachmentImageType: {
			[sentRemoteOptions setObject:@"image" forKey:@"type"];
			[sentRemoteOptions setObject:subtype forKey:@"image_meta"];
			break;
		}
		case WARemoteAttachmentDocumentType: {
			[sentRemoteOptions setObject:@"doc" forKey:@"type"];
			break;
		}
		case WARemoteAttachmentUnknownType:
		default: {
			[NSException raise:NSInternalInconsistencyException format:@"Could not send a file %@ with unknown remote type", aCopiedFileURL];
			break;
		}
	}
	
	void (^stitch)(id, NSString *) = ^ (id anObject, NSString *aKey) {
		if (anObject && aKey)
			[sentRemoteOptions setObject:anObject forKey:aKey];
	};
	
	stitch(title, @"title");
	stitch(description, @"description");
	stitch(proxyImage, @"image");
	stitch(updatedObjectID, @"object_id");
	
	[self.engine fireAPIRequestNamed:@"attachments/upload" withArguments:nil options:[NSDictionary dictionaryWithObjectsAndKeys:
	
		sentRemoteOptions, kIRWebAPIEngineRequestContextFormMultipartFieldsKey,
		@"POST", kIRWebAPIEngineRequestHTTPMethod,
	
	nil] validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
	
		if (successBlock)
			successBlock([inResponseOrNil objectForKey:@"object_id"]);
		
		[[NSFileManager defaultManager] removeItemAtURL:aCopiedFileURL error:nil];
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(^ (NSError *anError){
	
		if (failureBlock)
			failureBlock(anError);
			
		[[NSFileManager defaultManager] removeItemAtURL:aCopiedFileURL error:nil];
	
	})];

}

- (void) retrieveAttachment:(NSString *)anIdentifier onSuccess:(void(^)(NSDictionary *attachmentRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"attachments/get" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		anIdentifier, @"object_id",
	
	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
		
		if (!successBlock)
			return;
		
		successBlock(inResponseOrNil);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) deleteAttachment:(NSString *)anIdentifier onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"attachments/delete" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
	
		anIdentifier, @"object_id",
	
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
		
		if (successBlock)
			successBlock();
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveThumbnailForAttachment:(NSString *)anIdentifier ofType:(WARemoteAttachmentType)aType onSuccess:(void(^)(NSURL *aThumbnailURL))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"attachments/view" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		anIdentifier, @"object_id",
		@"large", @"image_meta",
	
	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
		
		if (successBlock)
			successBlock([inResponseOrNil valueForKeyPath:@"redirect_to"]);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) createAttachmentWithFileAtURL:(NSURL *)aFileURL inGroup:(NSString *)aGroupIdentifier representingImageURL:(NSURL *)aRepresentingImageForBinaryTypesOrNil withTitle:(NSString *)aTitle description:(NSString *)aDescription replacingAttachment:(NSString *)replacedAttachmentIdentifierOrNil asType:(WARemoteAttachmentType)aType onSuccess:(void(^)(NSString *attachmentIdentifier))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSMutableDictionary *options = [NSMutableDictionary dictionary];
	
	if (aRepresentingImageForBinaryTypesOrNil)
		[options setObject:aRepresentingImageForBinaryTypesOrNil forKey:kWARemoteAttachmentRepresentingImageURL];
	
	if (aTitle)
		[options setObject:aTitle forKey:kWARemoteAttachmentTitle];
		
	if (aDescription)
		[options setObject:aDescription forKey:kWARemoteAttachmentDescription];
		
	if (replacedAttachmentIdentifierOrNil)
		[options setObject:replacedAttachmentIdentifierOrNil forKey:kWARemoteAttachmentUpdatedObjectIdentifier];
	
	if (aType)
		[options setObject:[NSNumber numberWithUnsignedInteger:aType] forKey:kWARemoteAttachmentType];

	[self createAttachmentWithFile:aFileURL group:aGroupIdentifier options:options onSuccess:successBlock onFailure:failureBlock];

}

@end
