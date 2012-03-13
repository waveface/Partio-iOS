//
//  IRManagedObject+WAFileHandling.h
//  wammer
//
//  Created by Evadne Wu on 3/9/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "IRManagedObject.h"

@interface IRManagedObject (WAFileHandling)

- (NSString *) relativePathFromPath:(NSString *)absolutePath;
- (NSString *) absolutePathFromPath:(NSString *)relativePath;

@end
