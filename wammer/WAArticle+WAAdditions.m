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

- (WAFile *) representingFile {

	[self willAccessValueForKey:@"representingFile"];
	WAFile *file = [self primitiveValueForKey:@"representingFile"];
	[self didAccessValueForKey:@"representingFile"];
	
	if (!file) {
	
		[self willAccessValueForKey:@"files"];
		NSOrderedSet *files = [self primitiveValueForKey:@"files"];
		
		if ([files count]) {
			file = [[files array] objectAtIndex:0];
		}

		[self didAccessValueForKey:@"files"];
	
	}
	
	return file;

}

- (void) setRepresentingFile:(WAFile *)representingFile {

	[self willChangeValueForKey:@"representingFile"];
	[self setPrimitiveValue:representingFile forKey:@"representingFile"];
	[self didChangeValueForKey:@"representingFile"];

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

+ (BOOL) automaticallyNotifiesObserversForKey:(NSString *)key {

	if ([super automaticallyNotifiesObserversForKey:key])
		return YES;
	
	if ([key isEqualToString:@"text"])
		return YES;
	
	if ([key isEqualToString:@"files"])
		return YES;
	
	return YES;

}

- (NSDate *) presentationDate {

	return self.creationDate;

}

@end
