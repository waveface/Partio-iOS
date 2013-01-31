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
#import <Foundation/Foundation.h>
#import "WAFileExif+WAAdditions.h"
#import "WAFile+WARemoteInterfaceEntitySyncing.h"
#import <SSToolkit/NSDate+SSToolkitAdditions.h>

NSString * const kWARemoteAttachmentType = @"WARemoteAttachmentType";
NSString * const kWARemoteAttachmentTitle = @"WARemoteAttachmentTitle";
NSString * const kWARemoteAttachmentDescription = @"WARemoteAttachmentDescription";
NSString * const kWARemoteAttachmentRepresentingImageURL = @"WARemoteAttachmentRepresentingImageURL";
NSString * const kWARemoteAttachmentUpdatedObjectIdentifier = @"WARemoteAttachmentUpdatedObjectIdentifier";
NSString * const kWARemoteAttachmentSubtype = @"kWARemoteAttachmentDestinationImageType";
NSString * const kWARemoteArticleIdentifier = @"kWARemoteArticleIdentifier";
NSString * const kWARemoteAttachmentExif = @"kWARemoteAttachmentExif";
NSString * const kWARemoteAttachmentCreateTime = @"kWARemoteAttachmentCreateTime";
NSString * const kWARemoteAttachmentImportTime = @"kWARemoteAttachmentImportTime";
NSString * const WARemoteAttachmentOriginalSubtype = @"origin";
NSString * const WARemoteAttachmentLargeSubtype = @"large";
NSString * const WARemoteAttachmentMediumSubtype = @"medium";
NSString * const WARemoteAttachmentSmallSubtype = @"small";


@implementation WARemoteInterface (Attachments)

- (void)createAttachmentWithFile:(NSURL *)aFileURL group:(NSString *)aGroupIdentifier options:(NSDictionary *)options onSuccess:(void (^)(NSString *))successBlock onFailure:(void (^)(NSError *))failureBlock {
  
  if ([aFileURL isFileURL]) {
    
    NSData *fileData = [NSData dataWithContentsOfFile:[aFileURL path] options:NSDataReadingMappedIfSafe error:nil];
    [self createAttachmentWithFileData:fileData name:[[aFileURL path] lastPathComponent] group:aGroupIdentifier options:options onSuccess:successBlock onFailure:failureBlock];
    
  } else {
    
    [[WAAssetsLibraryManager defaultManager] assetForURL:aFileURL resultBlock:^(ALAsset *asset) {
      
      if (!asset) {
        failureBlock(WAFileEntitySyncingError(WAFileSyncingErrorCodeAssetDeleted, @"asset is deleted", nil));
        return;
      }

      long long fileSize = [[asset defaultRepresentation] size];
      Byte *byteData = (Byte *)malloc(fileSize);
      [[asset defaultRepresentation] getBytes:byteData fromOffset:0 length:fileSize error:nil];
      NSData *fileData = [NSData dataWithBytesNoCopy:byteData length:fileSize freeWhenDone:YES];
      [self createAttachmentWithFileData:fileData name:[[asset defaultRepresentation] filename] group:aGroupIdentifier options:options onSuccess:successBlock onFailure:failureBlock];
      
    } failureBlock:^(NSError *error) {
      
      failureBlock(error);
      
    }];
    
  }
  
}

- (void) createAttachmentWithFileData:(NSData *)fileData name:(NSString *)aFileName group:(NSString *)aGroupIdentifier options:(NSDictionary *)options onSuccess:(void(^)(NSString *attachmentIdentifier))successBlock onFailure:(void(^)(NSError *error))failureBlock {
  
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
  NSString *articleIdentifier = [mergedOptions objectForKey:kWARemoteArticleIdentifier];
  NSString *fileCreateTime = [[mergedOptions objectForKey:kWARemoteAttachmentCreateTime] ISO8601String];
  NSString *fileImportTime = [[mergedOptions objectForKey:kWARemoteAttachmentImportTime] ISO8601String];
  NSString *timezone = [NSString stringWithFormat:@"%d", [[NSTimeZone localTimeZone] secondsFromGMT]/60];
  WAFileExif *exif = [mergedOptions objectForKey:kWARemoteAttachmentExif];
  NSString *exifJsonString = nil;
  if (exif) {
    NSDictionary *exifData = [exif remoteRepresentation];
    if ([NSJSONSerialization isValidJSONObject:exifData]) {
      NSError *error = nil;
      NSData *exifJsonData = [NSJSONSerialization dataWithJSONObject:exifData options:0 error:&error];
      if (error) {
        NSLog(@"Unable to create EXIF JSON data from %@", exifData);
      }
      exifJsonString = [[NSString alloc] initWithData:exifJsonData encoding:NSUTF8StringEncoding];
    }
  }
  
  NSMutableDictionary *sentRemoteOptions = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				    aFileName, @"file",
				    fileData, @"file_data",
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
      [NSException raise:NSInternalInconsistencyException format:@"Could not send a file %@ with unknown remote type", aFileName];
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
  stitch(articleIdentifier, @"post_id");
  stitch(exifJsonString, @"exif");
  stitch(fileCreateTime, @"file_create_time");
  stitch(fileImportTime, @"import_time");
  stitch(timezone, @"timezone");
  
  [self.engine fireAPIRequestNamed:@"attachments/upload" withArguments:nil options:[NSDictionary dictionaryWithObjectsAndKeys:
								    
								    sentRemoteOptions, kIRWebAPIEngineRequestContextFormMultipartFieldsKey,
								    @"POST", kIRWebAPIEngineRequestHTTPMethod,
								    
								    nil] validator:WARemoteInterfaceGenericNoErrorValidator() successHandler: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
    
    if (successBlock)
      successBlock([inResponseOrNil objectForKey:@"object_id"]);
    
  } failureHandler:WARemoteInterfaceGenericFailureHandler(^ (NSError *anError){
    
    if (failureBlock)
      failureBlock(anError);
    
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

- (void)createAttachmentMetas:(NSArray *)metas onSuccess:(void (^)(NSArray *successIDs))successBlock onFailure:(void (^)(NSError *))failureBlock {
  
  if ([NSJSONSerialization isValidJSONObject:metas]) {
    
    NSError *error = nil;
    NSData *sentMetadata = [NSJSONSerialization dataWithJSONObject:metas options:0 error:&error];
    NSString *sentMetadataString = [[NSString alloc] initWithData:sentMetadata encoding:NSUTF8StringEncoding];
    
    if (error) {
      
      NSLog(@"Unable to convert JSON from attachment metas: %@", metas);
      
    } else {
      
      NSDictionary *apiOptions = @{
    kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey:@{@"metadata":sentMetadataString},
    kIRWebAPIEngineRequestHTTPMethod:@"POST"
      };
      
      [self.engine fireAPIRequestNamed:@"attachments/upload_metadata"
		     withArguments:nil
			 options:apiOptions
		         validator:WARemoteInterfaceGenericNoErrorValidator()
		    successHandler: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
		      NSMutableArray *successIDs = [NSMutableArray arrayWithArray:inResponseOrNil[@"success_ids"]];
		      NSArray *failureIDs = inResponseOrNil[@"failure_ids"];
		      for (NSArray *failureID in failureIDs) {
		        // Duplicated object_id
		        if ([failureID[1] isEqualToNumber:@(0x6000+70)]) {
			[successIDs addObject:failureID[0]];
		        }
		      }
		      if (successBlock)
		        successBlock(successIDs);}
		    failureHandler:WARemoteInterfaceGenericFailureHandler(^ (NSError *anError){
        if (failureBlock)
	failureBlock(anError);})];
      
    }
    
  }
  
}

- (void)retrieveMetaForAttachments:(NSArray *)identifiers onSuccess:(void(^)(NSArray *))successBlock onFailure:(void(^)(NSError *))failureBlock {
  
  if ([NSJSONSerialization isValidJSONObject:identifiers]) {
    NSError *error = nil;
    NSData *sentIdentifiers = [NSJSONSerialization dataWithJSONObject:identifiers options:0 error:&error];
    NSString *sentIdentifiersString = [[NSString alloc] initWithData:sentIdentifiers encoding:NSUTF8StringEncoding];
    if (error) {
      NSLog(@"Unable to convert JSON from attachment identifiers: %@", identifiers);
    } else {
      NSDictionary *apiOptions = @{
    kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey:@{@"object_ids":sentIdentifiersString},
    kIRWebAPIEngineRequestHTTPMethod:@"POST"
      };
      
      [self.engine fireAPIRequestNamed:@"attachments/multiple_get"
		     withArguments:nil
			 options:apiOptions
		         validator:WARemoteInterfaceGenericNoErrorValidator()
		    successHandler: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
		      if (successBlock)
		        successBlock(inResponseOrNil[@"results"]);}
		    failureHandler:WARemoteInterfaceGenericFailureHandler(^ (NSError *anError){
        if (failureBlock)
	failureBlock(anError);})];
    }
  }
  
}

- (void)hideAttachments:(NSArray *)identifiers onSuccess:(void (^)(NSArray *successIDs))successBlock onFailure:(void (^)(NSError *))failureBlock {
  
  if ([NSJSONSerialization isValidJSONObject:identifiers]) {
    NSError *error = nil;
    NSData *sentIdentifiers = [NSJSONSerialization dataWithJSONObject:identifiers options:0 error:&error];
    NSString *sentIdentifiersString = [[NSString alloc] initWithData:sentIdentifiers encoding:NSUTF8StringEncoding];
    if (error) {
      NSLog(@"Unable to convert JSON from attachment identifiers: %@", identifiers);
    } else {
      NSDictionary *apiOptions = @{
    kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey:@{@"object_ids":sentIdentifiersString},
    kIRWebAPIEngineRequestHTTPMethod:@"POST"
      };
      
      [self.engine fireAPIRequestNamed:@"attachments/hide"
		     withArguments:nil
			 options:apiOptions
		         validator:WARemoteInterfaceGenericNoErrorValidator()
		    successHandler: ^ (NSDictionary *inResponseOrNil, IRWebAPIRequestContext *inResponseContext) {
		      if (successBlock)
		        successBlock(inResponseOrNil[@"success_ids"]);}
		    failureHandler:WARemoteInterfaceGenericFailureHandler(^ (NSError *anError){
        if (failureBlock)
	failureBlock(anError);})];
    }
  }
}
@end
