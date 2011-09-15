//
//  WAGalleryImageView.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/5/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>


//	This is a very simple wrapper around an activity indicator and a zoomable image view

@interface WAGalleryImageView : UIView

+ (WAGalleryImageView *) viewForImage:(UIImage *)image;

@property (nonatomic, readwrite, retain) UIImage *image;
- (void) setImage:(UIImage *)newImage animated:(BOOL)animate;

@end
