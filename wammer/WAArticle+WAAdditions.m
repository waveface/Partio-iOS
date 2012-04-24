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
	
	if (!file && [self.fileOrder count]) {
		file = (WAFile *)[self irObjectAtIndex:0 inArrayKeyed:@"fileOrder"];
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

- (void) setFiles:(NSSet *)files {

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

- (void) setFileOrder:(NSArray *)fileOrder {

	[self willChangeValueForKey:@"fileOrder"];
	[self setPrimitiveValue:fileOrder forKey:@"fileOrder"];
	
	[self willAccessValueForKey:@"representingFile"];
	WAFile *representingFile = [self primitiveValueForKey:@"representingFile"];
	[self didAccessValueForKey:@"representingFile"];
	
	if ([[representingFile objectID] isTemporaryID])
		[representingFile.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:representingFile] error:nil];
	
	if (![fileOrder containsObject:[[representingFile objectID] URIRepresentation]]) {
		[self willChangeValueForKey:@"representingFile"];
		[self setPrimitiveValue:nil forKey:@"representingFile"];
		[self didChangeValueForKey:@"representingFile"];
	}
	
	[self didChangeValueForKey:@"fileOrder"];

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

- (NSDate *) presentationDate {

	return self.creationDate;

}

@end
