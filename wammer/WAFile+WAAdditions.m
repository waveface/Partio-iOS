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


static NSString * const kMemoryWarningObserver = @"-[WAFile(WAAdditions) handleDidReceiveMemoryWarning:]";

@implementation WAFile (WAAdditions)

- (id) initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context {

	self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
	if (!self)
		return nil;
	
	if ([NSThread isMainThread]) {
		
		__weak WAFile *wSelf = self;
	
		id observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
		
			[wSelf handleDidReceiveMemoryWarning:note];
			
		}];
	
		objc_setAssociatedObject(self, &kMemoryWarningObserver, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	}
	
	return self;

}

- (void) handleDidReceiveMemoryWarning:(NSNotification *)aNotification {

	[self irAssociateObject:nil usingKey:&kWAFileThumbnailImage policy:OBJC_ASSOCIATION_ASSIGN changingObservedKey:nil];
	[self irAssociateObject:nil usingKey:&kWAFileLargeThumbnailImage policy:OBJC_ASSOCIATION_ASSIGN changingObservedKey:nil];
	[self irAssociateObject:nil usingKey:&kWAFileResourceImage policy:OBJC_ASSOCIATION_ASSIGN changingObservedKey:nil];

}

- (void) dealloc {

	id observer = objc_getAssociatedObject(self, &kMemoryWarningObserver);
	
	if (observer) {

		[[NSNotificationCenter defaultCenter] removeObserver:observer];
	
	}

}

- (void) awakeFromFetch {

  [super awakeFromFetch];
	
	if ([NSThread isMainThread] && ![self.objectID isTemporaryID])
		[self setAttemptsBlobRetrieval:YES notify:NO];
	
}

@end
