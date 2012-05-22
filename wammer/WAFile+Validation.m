//
//  WAFile+Validation.m
//  wammer
//
//  Created by Evadne Wu on 5/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFile+Validation.h"
#import "WAFile+WAConstants.h"
#import "WAFile+ImplicitBlobFulfillment.h"

#import "UIKit+IRAdditions.h"


@implementation WAFile (Validation)

- (BOOL) validateForInsert:(NSError **)error {

	if ([super validateForUpdate:error])
	if ([self validateChangedImagesWithError:error])
		return YES;
	
	return NO;

}

- (BOOL) validateForUpdate:(NSError **)error {

	if ([super validateForUpdate:error])
	if ([self validateChangedImagesWithError:error])
		return YES;
	
	return NO;

}

- (BOOL) validateChangedImagesWithError:(NSError **)outError {

	__block BOOL retVal = NO;

	[self performBlockSuppressingBlobRetrieval:^{
	
		NSArray *allKeys = [[self changedValues] allKeys];
		
		BOOL (^unchangedOrValid)(NSString *, NSError **) = ^ (NSString *key, NSError **outError) {

			if (![allKeys containsObject:key])
				return YES;
			
			NSString *filePath = [self valueForKey:key];
			
			if (![[filePath pathExtension] length]) {
				
				if (outError)
					*outError = [NSError errorWithDomain:@"com.waveface.WAFile" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
						[NSString stringWithFormat:@"File at path %@ must have a path extension", filePath], NSLocalizedDescriptionKey,
					nil]];
				
				return NO;
			
			}
			
			if (![UIImage validateContentsOfFileAtPath:filePath error:outError])
				return NO;
			
			BOOL isDirectory = NO;
			if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory] || isDirectory) {
			
				if (outError)
					*outError = [NSError errorWithDomain:@"com.waveface.WAFile" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
						[NSString stringWithFormat:@"File at path %@ must exist as a file for key value %@", filePath, key], NSLocalizedDescriptionKey,
					nil]];
				
				return NO;
				
			}
			
			return YES;
		
		};
		
		if (unchangedOrValid(kWAFileSmallThumbnailFilePath, outError))
		if (unchangedOrValid(kWAFileThumbnailFilePath, outError))
		if (unchangedOrValid(kWAFileLargeThumbnailFilePath, outError))
		if (unchangedOrValid(kWAFileResourceFilePath, outError))
			retVal = YES;
		
	}];
	
	return retVal;

}

@end
