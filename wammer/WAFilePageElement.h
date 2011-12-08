//
//  WAFilePageElement.h
//  wammer
//
//  Created by Evadne Wu on 12/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "CoreData+IRAdditions.h"

@class WAFile;

@interface WAFilePageElement : IRManagedObject

@property (nonatomic, retain) NSString * thumbnailFilePath;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) WAFile *file;

@end
