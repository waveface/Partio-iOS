//
//  WAFile+WAAdditions.m
//  wammer
//
//  Created by Evadne Wu on 1/8/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <objc/runtime.h>

#import "Foundation+IRAdditions.h"
#import "CGGeometry+IRAdditions.h"
#import "UIImage+IRAdditions.h"

#import "WADataStore.h"
#import "WARemoteInterface.h"

#import "WAFile+WAConstants.h"
#import "WAFile+CoreDataGeneratedPrimitiveAccessors.h"

#import "WAFile+ImplicitBlobFulfillment.h"
#import "WAFile+Validation.h"
#import "WAFile+LazyImages.h"


@implementation WAFile (WAAdditions)

- (void) dealloc {

	[self disableMemoryWarningObserverCreation];
	[self removeMemoryWarningObserverIfAppropriate];

}

- (void) awakeFromFetch {

  [super awakeFromFetch];
	
	if ([NSThread isMainThread] && ![self.objectID isTemporaryID])
		[self setAttemptsBlobRetrieval:YES notify:NO];
	
}

- (void) willTurnIntoFault {

	[super willTurnIntoFault];
	
	[self removeMemoryWarningObserverIfAppropriate];

}

@end
