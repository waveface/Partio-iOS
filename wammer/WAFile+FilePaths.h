//
//  WAFile+FilePaths.h
//  wammer
//
//  Created by Evadne Wu on 5/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFile.h"

@interface WAFile (FilePaths)

- (NSString *) filePathForKey:(NSString *)filePathKey usingFileURLStringKey:(NSString *)urlStringKey;

- (void) setFilePath:(NSString *)newAbsoluteFilePath forKey:(NSString *)filePathKey replacingImageKey:(NSString *)imageKey;

@end
