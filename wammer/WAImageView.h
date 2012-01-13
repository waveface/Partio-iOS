//
//  WAImageView.h
//  wammer
//
//  Created by Evadne Wu on 9/30/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>


#ifndef __WAImageView__
#define __WAImageView__

enum {	
	
	WAImageViewForceAsynchronousOption = 1,
	WAImageViewForceSynchronousOption = 2
	
}; typedef NSUInteger WAImageViewOptions;

#endif


@class WAImageView;
@protocol WAImageViewDelegate 

- (void) imageViewDidUpdate:(WAImageView *)anImageView;

@end


@interface WAImageView : UIImageView

+ (Class) preferredClusterClass;

@property (nonatomic, readwrite, assign) id<WAImageViewDelegate> delegate;

- (void) setImage:(UIImage *)anImage withOptions:(WAImageViewOptions)options;

@end
