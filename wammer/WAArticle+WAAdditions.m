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

+ (BOOL) automaticallyNotifiesObserversForKey:(NSString *)key {

	if ([super automaticallyNotifiesObserversForKey:key])
		return YES;
	
	if ([key isEqualToString:@"files"])
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

- (void) irAwake {

	[super irAwake];
	[self irReconcileObjectOrderWithKey:@"files" usingArrayKeyed:@"fileOrder"];
	
}

- (NSArray *) fileOrder {

	return [self irBackingOrderArrayKeyed:@"fileOrder"];

}

- (void) didChangeValueForKey:(NSString *)inKey withSetMutation:(NSKeyValueSetMutationKind)inMutationKind usingObjects:(NSSet *)inObjects {

	if ([inKey isEqualToString:@"files"]) {
    
    [self irUpdateObjects:inObjects withRelationshipKey:@"files" usingOrderArray:@"fileOrder" withSetMutation:inMutationKind];
		return;
    
  }

	[super didChangeValueForKey:inKey withSetMutation:inMutationKind usingObjects:inObjects];
	
}

@end
