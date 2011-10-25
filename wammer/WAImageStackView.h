//
//  WAImageStackView.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/28/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>


#ifndef __WAImageStackView__
#define __WAImageStackView__

enum {
  WAImageStackViewInteractionNormal = 0,
  WAImageStackViewInteractionZoomInPossible
}; typedef NSUInteger WAImageStackViewInteractionState;

#endif


@class WAImageStackView;


@protocol WAImageStackViewDelegate <NSObject>

- (void) imageStackView:(WAImageStackView *)aStackView didRecognizePinchZoomGestureWithRepresentedImage:(UIImage *)representedImage contentRect:(CGRect)aRect transform:(CATransform3D)layerTransform;

@optional
- (void) imageStackView:(WAImageStackView *)aStackView didChangeInteractionStateToState:(WAImageStackViewInteractionState)newState;

@end


@interface WAImageStackView : UIView

@property (nonatomic, readwrite, assign) IBOutlet id<WAImageStackViewDelegate> delegate;
@property (nonatomic, readwrite, assign) WAImageStackViewInteractionState state;
@property (nonatomic, readwrite, retain) NSArray *images;
@property (nonatomic, readwrite, assign) NSUInteger maxNumberOfImages;

@property (nonatomic, readonly, assign) UIView *firstPhotoView;
@property (nonatomic, readonly, assign) BOOL gestureProcessingOngoing;

//	Actually implement these so the iPhone app can use square images:
//	@property (nonatomic, readwrite, assign) float_t minAspectRatio;
//	@property (nonatomic, readwrite, assign) float_t maxAspectRatio;
//	@property (nonatomic, readwrite, assign) NSString *clippingContentGravity;

- (void) setImages:(NSArray *)newImages asynchronously:(BOOL)async withDecodingCompletion:(void(^)(void))aBlock;
- (void) reset;

@end
