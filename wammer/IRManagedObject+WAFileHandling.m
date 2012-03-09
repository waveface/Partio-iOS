//
//  IRManagedObject+WAFileHandling.m
//  wammer
//
//  Created by Evadne Wu on 3/9/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "IRManagedObject+WAFileHandling.h"
#import "WADataStore.h"

@implementation IRManagedObject (WAFileHandling)

- (NSString *) relativePathFromPath:(NSString *)absolutePath {

	WADataStore *const dataStore = [WADataStore defaultStore];
	return [dataStore relativePathWithBasePath:[dataStore persistentFileURLBasePath] filePath:absolutePath];

}

- (NSString *) absolutePathFromPath:(NSString *)relativePath {

	WADataStore *const dataStore = [WADataStore defaultStore];
	return [dataStore absolutePathWithBasePath:[dataStore persistentFileURLBasePath] filePath:relativePath];

}

@end
