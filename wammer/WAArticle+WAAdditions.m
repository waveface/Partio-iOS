//
//  WAArticle+WAAdditions.m
//  wammer
//
//  Created by Evadne Wu on 2/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAArticle+WAAdditions.h"

#import "WADataStore.h"

@implementation WAArticle (WAAdditions)

+ (void) load {

	[self configureSimulatedOrderedRelationship];

}

+ (NSSet *) keyPathsForValuesAffectingHasMeaningfulContent {

	return [NSSet setWithObjects:
	
		@"files",
		@"previews",
		@"text",
	
	nil];

}

- (BOOL) hasMeaningfulContent {

	if ([self.files count])
		return YES;
	
	if ([self.previews count])
		return YES;
	
	if ([[self.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
		return YES;

	return NO;

}

+ (NSSet *) keyPathsForValuesAffectingRepresentingFile {

	return [NSSet setWithObjects:
	
		@"files",
		@"fileOrder",
	
	nil];

}

- (WAFile *) representingFile {

	[self willAccessValueForKey:@"representingFile"];
	WAFile *file = [self primitiveValueForKey:@"representingFile"];
	[self didAccessValueForKey:@"representingFile"];
	
	if (file)
		return file;
	
	if ([self.fileOrder count])
		file = (WAFile *)[self irObjectAtIndex:0 inArrayKeyed:@"fileOrder"];

	return file;

}

+ (BOOL) automaticallyNotifiesObserversForKey:(NSString *)key {

	if ([super automaticallyNotifiesObserversForKey:key])
		return YES;
	
	if ([key isEqualToString:@"text"])
		return YES;
	
	return NO;

}

+ (NSSet *) keyPathsForValuesAffectingFiles {

	return [NSSet setWithObjects:@"fileOrder", nil];

}

+ (NSSet *) keyPathsForValuesAffectingFileOrder {

	return [NSSet setWithObjects:@"files", nil];

}

+ (NSDictionary *) orderedRelationships {

	return [NSDictionary dictionaryWithObjectsAndKeys:
		
		@"fileOrder", @"files",
		
	nil];

}

@end
