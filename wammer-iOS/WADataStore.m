//
//  WADataStore.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/21/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WADataStore.h"

@implementation WADataStore

+ (WADataStore *) defaultStore {
	
	return (WADataStore *)[super defaultStore];
	
}

- (WADataStore *) initWithManagedObjectModel:(NSManagedObjectModel *)model {
	
	return (WADataStore *)[super initWithManagedObjectModel:model];
	
}

- (NSManagedObjectModel *) defaultManagedObjectModel {

	return [[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"WAModel" withExtension:@"momd"]];

}

@end
