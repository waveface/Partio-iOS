//
//  WAFile+WAAdditions.h
//  wammer
//
//  Created by Evadne Wu on 1/8/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFile.h"

@interface WAFile (WAAdditions)

@property (nonatomic, readonly, retain) UIImage *resourceImage;
@property (nonatomic, readonly, retain) UIImage *largeThumbnailImage;
@property (nonatomic, readonly, retain) UIImage *thumbnailImage;

- (UIImage *) presentableImage;	//	Conforms to KVO; automatically chooses the highest resolution thing

+ (dispatch_queue_t) sharedResourceHandlingQueue;

@end
