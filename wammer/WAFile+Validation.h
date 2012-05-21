//
//  WAFile+Validation.h
//  wammer
//
//  Created by Evadne Wu on 5/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFile.h"

@interface WAFile (Validation)

- (BOOL) validateForInsert:(NSError **)error;
- (BOOL) validateForUpdate:(NSError **)error;

@end
