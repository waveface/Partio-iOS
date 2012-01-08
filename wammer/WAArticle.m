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
@dynamic previews;
@dynamic group;
@dynamic owner;
@dynamic fileOrder;
@dynamic draft;

+ (BOOL) automaticallyNotifiesObserversForKey:(NSString *)key {

	if ([super automaticallyNotifiesObserversForKey:key])
		return YES;
	
	if ([key isEqualToString:@"files"])
		return YES;
	
	return NO;

}

- (id) initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context {

	self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
	if (!self)
		return nil;
	
	[self addObserver:self forKeyPath:@"files" options:NSKeyValueObservingOptionNew context:nil];

	return self;

}

- (void) irAwake {

	[super irAwake];
	[self irReconcileObjectOrderWithKey:@"files" usingArrayKeyed:@"fileOrder"];
	
}

- (void) dealloc {

	[self removeObserver:self forKeyPath:@"files"];
	
	[super dealloc];

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

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	NSLog(@"%s %@ %@ %@ %@", __PRETTY_FUNCTION__, keyPath, object, change, context);

}

@end
