//
//  WAEventPhotoPickerDataSource.h
//  wammer
//
//  Created by Shen Steven on 5/13/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WAAssetsLibraryManager.h"

@interface WAEventPhotoPickerDataSource : NSObject

- (id) initWithPhotosLoadedUntil:(NSDate*)until completionHandler:(void(^)(void))completionHandler;
- (id) initWithCompletionHandler:(void(^)(void))completionHandler;
- (NSUInteger) numberOfEvents;
- (NSUInteger) numberOfPhotosInEvent:(NSUInteger)eventSection;
- (NSArray*) photosInEvent:(NSUInteger)eventSection;
- (ALAsset *) photoAtIndexPath:(NSIndexPath*)indexPath;
- (BOOL) loadMoreEvents;

@end
