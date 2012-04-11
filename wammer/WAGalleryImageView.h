//
//  WAGalleryImageView.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/5/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIKit+IRAdditions.h"

@class WAGalleryImageView;
@protocol WAGalleryImageViewDelegate <NSObject>

- (void) galleryImageViewDidBeginInteraction:(WAGalleryImageView *)imageView;

@end


@interface WAGalleryImageView : IRView

+ (WAGalleryImageView *) viewForImage:(UIImage *)image;

@property (nonatomic, readwrite, assign) id<WAGalleryImageViewDelegate> delegate;

@property (nonatomic, readwrite, retain) UIImage *image;
- (void) setImage:(UIImage *)newImage animated:(BOOL)animate;
- (void) setImage:(UIImage *)newImage animated:(BOOL)animate synchronized:(BOOL)sync;

- (void) handleDoubleTap:(UITapGestureRecognizer *)aRecognizer;
- (void) reset;

@end
