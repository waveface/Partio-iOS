//
//  WAArticle.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/27/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "WAArticle.h"
#import "WAUser.h"
#import "WADataStore.h"


@implementation WAArticle

@dynamic creationDeviceName;
@dynamic identifier;
@dynamic text;
@dynamic timestamp;
@dynamic comments;
@dynamic files;
@dynamic owner;
@dynamic fileOrder;
@dynamic draft;

+ (NSString *) keyPathHoldingUniqueValue {

	return @"identifier";

}

+ (BOOL) skipsNonexistantRemoteKey {

	//	Allows piecemeal data patching, by skipping code path that assigns a placeholder value for any missing value
	//	that -configureWithRemoteDictionary: gets
	return YES;
	
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {

	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
			@"creationDeviceName", @"creation_device_name",
			@"identifier", @"id",
			@"text", @"text",
			@"timestamp", @"timestamp",
			@"files", @"files",
			@"comments", @"comments",
			@"owner", @"owner",
			//	@"creator_id" this needs transforming
		nil];
		
		[mapping retain];
		
	});

	return mapping;

}

+ (id) transformedValue:(id)aValue fromRemoteKeyPath:(NSString *)aRemoteKeyPath toLocalKeyPath:(NSString *)aLocalKeyPath {

	if ([aLocalKeyPath isEqualToString:@"timestamp"])
		return [[WADataStore defaultStore] dateFromISO8601String:aValue];
	
	return [super transformedValue:aValue fromRemoteKeyPath:aRemoteKeyPath toLocalKeyPath:aLocalKeyPath];

}





- (void) awakeFromFetch {

	NSArray *primitiveFileOrder = [self primitiveValueForKey:@"fileOrder"];
	if (!primitiveFileOrder)
		primitiveFileOrder = [NSArray array];
	
	[((NSManagedObject *)[self.files anyObject]).managedObjectContext obtainPermanentIDsForObjects:[self.files allObjects] error:nil];
	NSArray *allFileObjectURIs = [[self.files allObjects] irMap: ^ (NSManagedObject *inObject, int index, BOOL *stop) {
		return [[inObject objectID] URIRepresentation];
	}];
	
	if ([primitiveFileOrder count] != [allFileObjectURIs count]) {
	
		NSMutableArray *reconciledFileOrder = [NSMutableArray array];
		for (NSURL *anObjectURI in primitiveFileOrder)
			if (![reconciledFileOrder containsObject:anObjectURI])
				if ([allFileObjectURIs containsObject:anObjectURI])
					[reconciledFileOrder addObject:anObjectURI];
		
		primitiveFileOrder = reconciledFileOrder;
		
	}
	
	NSSet *orderedFileURIs = [NSSet setWithArray:primitiveFileOrder];
	NSSet *existingFileURIs = [NSSet setWithArray:allFileObjectURIs];
		
	if (![orderedFileURIs isEqual:existingFileURIs]) {
	
		NSMutableArray *newPrimitiveFileOrder = [[primitiveFileOrder mutableCopy] autorelease];
		
		[newPrimitiveFileOrder removeObjectsAtIndexes:[newPrimitiveFileOrder indexesOfObjectsPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
			return (BOOL)(![existingFileURIs containsObject:obj]);
		}]];
		
		[newPrimitiveFileOrder addObjectsFromArray:[[existingFileURIs objectsPassingTest:^BOOL(id obj, BOOL *stop) {
			return (BOOL)(![orderedFileURIs containsObject:obj]);
		}] allObjects]];
	
	}
		
	[self setPrimitiveValue:primitiveFileOrder forKey:@"fileOrder"];
	
}

- (NSArray *) fileOrder {

	NSArray *returnedOrder = [self primitiveValueForKey:@"fileOrder"];
	
	if (!returnedOrder) {
		returnedOrder = [NSArray array];
	//	[self willChangeValueForKey:@"fileOrder"];
		[self setPrimitiveValue:returnedOrder forKey:@"fileOrder"];
	//	[self didChangeValueForKey:@"fileOrder"];
	}
	
	return returnedOrder;

}

- (void) didChangeValueForKey:(NSString *)inKey withSetMutation:(NSKeyValueSetMutationKind)inMutationKind usingObjects:(NSSet *)inObjects {

	[super didChangeValueForKey:inKey withSetMutation:inMutationKind usingObjects:inObjects];
	
	if (![inKey isEqualToString:@"files"])
		return;

	[((NSManagedObject *)[inObjects anyObject]).managedObjectContext obtainPermanentIDsForObjects:[inObjects allObjects] error:nil];
	
	NSArray *inObjectURIs = [[inObjects allObjects] irMap: ^ (NSManagedObject *inObject, int index, BOOL *stop) {
		return [[inObject objectID] URIRepresentation];
	}];
	
	switch (inMutationKind) {
	
		case NSKeyValueUnionSetMutation: {
			
			NSMutableArray *newFileOrder = [[self.fileOrder mutableCopy] autorelease];
			[newFileOrder addObjectsFromArray:inObjectURIs];
			self.fileOrder = newFileOrder;
			
			break;
			
		}
		
		case NSKeyValueMinusSetMutation: {
			
			NSMutableArray *newFileOrder = [[self.fileOrder mutableCopy] autorelease];
			[newFileOrder removeObjectsInArray:[self.fileOrder objectsAtIndexes:[self.fileOrder indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) { return [inObjectURIs containsObject:obj]; }]]];
			self.fileOrder = newFileOrder;
			
			break;
			
		}
		
		case NSKeyValueIntersectSetMutation: {
		
			NSMutableArray *newFileOrder = [[self.fileOrder mutableCopy] autorelease];
			[newFileOrder removeObjectsInArray:inObjectURIs];
			self.fileOrder = newFileOrder;
			
			break;
			
		}
		
		case NSKeyValueSetSetMutation: {
		
			self.fileOrder = inObjectURIs;
			break;
			
		}
	
	}

}

@end
