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
	
	nil];

}

- (WAFile *) representingFile {

	[self willAccessValueForKey:@"representingFile"];
	WAFile *file = [self primitiveValueForKey:@"representingFile"];
	[self didAccessValueForKey:@"representingFile"];
	
	if (!file && [self.files count]) {
		file = [self.files objectAtIndex:0];
	}

	return file;

}

- (void) setRepresentingFile:(WAFile *)representingFile {

	if (representingFile) {
	
		[self willAccessValueForKey:@"files"];
		NSSet *files = [self primitiveValueForKey:@"files"];
		[self didAccessValueForKey:@"files"];
		
		if (![files containsObject:representingFile]) {
			[self addFilesObject:representingFile];
			NSParameterAssert([files containsObject:representingFile]);
		}
	
	}
	
	[self willChangeValueForKey:@"representingFile"];
	[self setPrimitiveValue:representingFile forKey:@"representingFile"];
	[self didChangeValueForKey:@"representingFile"];

}

- (void) setFiles:(NSOrderedSet *)files {

	[self willChangeValueForKey:@"files"];
	[self setPrimitiveValue:files forKey:@"files"];

	[self willAccessValueForKey:@"representingFile"];
	WAFile *representingFile = [self primitiveValueForKey:@"representingFile"];
	[self didAccessValueForKey:@"representingFile"];
		
	if (![files containsObject:representingFile]) {
		[self willChangeValueForKey:@"representingFile"];
		[self setPrimitiveValue:nil forKey:@"representingFile"];
		[self didChangeValueForKey:@"representingFile"];
	}		
	
	[self didChangeValueForKey:@"files"];

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
