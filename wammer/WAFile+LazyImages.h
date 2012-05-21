//
//  WAFile+LazyImages.h
//  wammer
//
//  Created by Evadne Wu on 5/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFile.h"

@interface WAFile (LazyImages)

@property (nonatomic, readonly, retain) UIImage *resourceImage;
@property (nonatomic, readonly, retain) UIImage *largeThumbnailImage;
@property (nonatomic, readonly, retain) UIImage *thumbnailImage;
@property (nonatomic, readonly, retain) UIImage *smallThumbnailImage;

- (UIImage *) smallestPresentableImage;	//	Conforms to KVO; automatically chooses the lowest resolution thing
- (UIImage *) bestPresentableImage;	//	Conforms to KVO; automatically chooses the highest resolution thing

@end
