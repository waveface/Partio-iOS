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

#import "WAFileExif.h"

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


@implementation NSNumber (WAAdditions)

/* Convert NSNumber to rational value
 * ref: http://www.ics.uci.edu/~eppstein/numth/frap.c
 */
- (NSArray *) rationalValue {

	long m[2][2];
	double x, startx;
	const long MAXDENOM = 10000;
	long ai;

	startx = x = [self doubleValue];

	/* initialize matrix */
	m[0][0] = m[1][1] = 1;
	m[0][1] = m[1][0] = 0;

	/* loop finding terms until denom gets too big */
	while (m[1][0] *  ( ai = (long)x ) + m[1][1] <= MAXDENOM) {
		long t;
		t = m[0][0] * ai + m[0][1];
		m[0][1] = m[0][0];
		m[0][0] = t;
		t = m[1][0] * ai + m[1][1];
		m[1][1] = m[1][0];
		m[1][0] = t;
		if(x==(double)ai) break;     // AF: division by zero
		x = 1/(x - (double) ai);
		if(x>(double)0x7FFFFFFF) break;  // AF: representation failure
	}

	return @[[NSNumber numberWithLong:m[0][0]], [NSNumber numberWithLong:m[1][0]]];

}

@end


@implementation WARemoteInterface (Attachments)

- (void)createAttachmentWithFile:(NSURL *)aFileURL group:(NSString *)aGroupIdentifier options:(NSDictionary *)options onSuccess:(void (^)(NSString *))successBlock onFailure:(void (^)(NSError *))failureBlock {

	if ([aFileURL isFileURL]) {

		NSData *fileData = [NSData dataWithContentsOfFile:[aFileURL path] options:NSDataReadingMappedIfSafe error:nil];		
		[self createAttachmentWithFileData:fileData name:[[aFileURL path] lastPathComponent] group:aGroupIdentifier options:options onSuccess:successBlock onFailure:failureBlock];

	} else {

		[[WAAssetsLibraryManager defaultManager] assetForURL:aFileURL resultBlock:^(ALAsset *asset) {

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
	NSString *fileCreateTime = [[WADataStore defaultStore] ISO8601StringFromDate:[mergedOptions objectForKey:kWARemoteAttachmentCreateTime]];
	NSString *fileImportTime = [[WADataStore defaultStore] ISO8601StringFromDate:[mergedOptions objectForKey:kWARemoteAttachmentImportTime]];
	WAFileExif *exif = [mergedOptions objectForKey:kWARemoteAttachmentExif];
	NSString *exifJsonString = nil;
	if (exif) {
		NSMutableDictionary *exifData = [[NSMutableDictionary alloc] init];
		if (exif.dateTimeOriginal) {
			exifData[@"DateTimeOriginal"] = exif.dateTimeOriginal;
		}
		if (exif.dateTimeDigitized) {
			exifData[@"DateTimeDigitized"] = exif.dateTimeDigitized;
		}
		if (exif.dateTime) {
			exifData[@"DateTime"] = exif.dateTime;
		}
		if (exif.model) {
			exifData[@"Model"] = exif.model;
		}
		if (exif.make) {
			exifData[@"Make"] = exif.make;
		}
		if (exif.exposureTime) {
			exifData[@"ExposureTime"] = [exif.exposureTime rationalValue];
		}
		if (exif.fNumber) {
			exifData[@"FNumber"] = [exif.fNumber rationalValue];
		}
		if (exif.apertureValue) {
			exifData[@"ApertureValue"] = [exif.apertureValue rationalValue];
		}
		if (exif.focalLength) {
			exifData[@"FocalLength"] = [exif.focalLength rationalValue];
		}
		if (exif.flash) {
			exifData[@"Flash"] = exif.flash;
		}
		if (exif.isoSpeedRatings) {
			exifData[@"ISOSpeedRatings"] = exif.isoSpeedRatings;
		}
		if (exif.colorSpace) {
			exifData[@"ColorSpace"] = exif.colorSpace;
		}
		if (exif.whiteBalance) {
			exifData[@"WhiteBalance"] = exif.whiteBalance;
		}
		if (exif.gpsLongitude && exif.gpsLatitude) {
			NSMutableDictionary *gpsDic = [@{@"longitude":exif.gpsLongitude, @"latitude":exif.gpsLatitude} mutableCopy];
			if (exif.gpsDateStamp) {
				gpsDic[@"GPSDateStamp"] = exif.gpsDateStamp;
			}
			if (exif.gpsTimeStamp) {
				NSArray *timeFileds = [exif.gpsTimeStamp componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":."]];
				gpsDic[@"GPSTimeStamp"] = @[[@([timeFileds[0] integerValue]) rationalValue],
																		[@([timeFileds[1] integerValue]) rationalValue],
																		[@([timeFileds[2] integerValue]) rationalValue]];
			}
			exifData[@"gps"] = gpsDic;
		}

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

@end
