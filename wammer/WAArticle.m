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

- (void) awakeFromFetch {

  [super awakeFromFetch];
  
  [self irReconcileObjectOrderWithKey:@"files" usingArrayKeyed:@"fileOrder"];
	
}

- (NSArray *) fileOrder {

  return [self irBackingOrderArrayKeyed:@"fileOrder"];

}

- (void) didChangeValueForKey:(NSString *)inKey withSetMutation:(NSKeyValueSetMutationKind)inMutationKind usingObjects:(NSSet *)inObjects {

	[super didChangeValueForKey:inKey withSetMutation:inMutationKind usingObjects:inObjects];
	
	if ([inKey isEqualToString:@"files"]) {
    
    [self irUpdateObjects:inObjects withRelationshipKey:@"files" usingOrderArray:@"fileOrder" withSetMutation:inMutationKind];
		return;
    
  }

}

@end
