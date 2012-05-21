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

			if ([allKeys containsObject:key])
			if (![UIImage validateContentsOfFileAtPath:[self valueForKey:key] error:outError]) {
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
