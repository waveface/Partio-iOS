//
//  WARemoteInterface+Attachments.m
//  wammer
//
//  Created by Evadne Wu on 11/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface+Attachments.h"
#import "WADataStore.h"

@implementation WARemoteInterface (Attachments)

- (void) createAttachmentWithFileAtURL:(NSURL *)aFileURL inGroup:(NSString *)aGroupIdentifier representingImageURL:(NSURL *)aRepresentingImageForBinaryTypesOrNil withTitle:(NSString *)aTitle description:(NSString *)aDescription replacingAttachment:(NSString *)replacedAttachmentIdentifierOrNil asType:(WARemoteAttachmentType)aType onSuccess:(void(^)(NSString *attachmentIdentifier))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	NSURL *copiedFileURL = [[WADataStore defaultStore] persistentFileURLForFileAtURL:aFileURL];
	
	if (![copiedFileURL pathExtension])
		NSLog(@"No mine type, using octet/stream.");
	
	NSMutableDictionary *sentData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
	
		copiedFileURL, @"file",
		aGroupIdentifier, @"group_id",
	
	nil];
	
	if (aRepresentingImageForBinaryTypesOrNil)
		[sentData setObject:[aRepresentingImageForBinaryTypesOrNil absoluteString] forKey:@"image"];
	
	if (aTitle)
		[sentData setObject:aTitle forKey:@"title"];
	
	if (aDescription)
		[sentData setObject:aDescription forKey:@"description"];
	
	[sentData setObject:@"image" forKey:@"type"];
	
	if (replacedAttachmentIdentifierOrNil)
		[sentData setObject:replacedAttachmentIdentifierOrNil forKey:@"object_id"];
	
	[sentData setObject:@"origin" forKey:@"image_meta"];

	[self.engine fireAPIRequestNamed:@"attachments/upload" withArguments:nil options:[NSDictionary dictionaryWithObjectsAndKeys:
	
		sentData, kIRWebAPIEngineRequestContextFormMultipartFieldsKey,
		@"POST", kIRWebAPIEngineRequestHTTPMethod,
	
	nil] validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (successBlock)
			successBlock([inResponseOrNil objectForKey:@"object_id"]);
		
		[[NSFileManager defaultManager] removeItemAtURL:copiedFileURL error:nil];
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(^ (NSError *anError){
	
		if (failureBlock)
			failureBlock(anError);
			
		[[NSFileManager defaultManager] removeItemAtURL:copiedFileURL error:nil];
	
	})];

}

- (void) retrieveAttachment:(NSString *)anIdentifier onSuccess:(void(^)(NSDictionary *attachmentRep))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"attachments/get" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		anIdentifier, @"object_id",
	
	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (!successBlock)
			return;
		
		successBlock(inResponseOrNil);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) deleteAttachment:(NSString *)anIdentifier onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"attachments/delete" withArguments:nil options:WARemoteInterfaceEnginePostFormEncodedOptionsDictionary([NSDictionary dictionaryWithObjectsAndKeys:
	
		anIdentifier, @"object_id",
	
	nil], nil) validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (successBlock)
			successBlock();
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

- (void) retrieveThumbnailForAttachment:(NSString *)anIdentifier ofType:(WARemoteAttachmentType)aType onSuccess:(void(^)(NSURL *aThumbnailURL))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	[self.engine fireAPIRequestNamed:@"attachments/view" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		anIdentifier, @"object_id",
		@"large", @"image_meta",
	
	nil] options:nil validator:WARemoteInterfaceGenericNoErrorValidator() successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (successBlock)
			successBlock([inResponseOrNil valueForKeyPath:@"redirect_to"]);
		
	} failureHandler:WARemoteInterfaceGenericFailureHandler(failureBlock)];

}

@end
