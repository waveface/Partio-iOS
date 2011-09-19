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


@class WAImageStackView;


typedef enum {
  WAImageStackViewInteractionNormal = 0,
  WAImageStackViewInteractionZoomInPossible
} WAImageStackViewInteractionState;

@protocol WAImageStackViewDelegate <NSObject>
- (void) imageStackView:(WAImageStackView *)aStackView didRecognizePinchZoomGestureWithRepresentedImage:(UIImage *)representedImage contentRect:(CGRect)aRect transform:(CATransform3D)layerTransform;
@end


@interface WAImageStackView : UIView

@property (nonatomic, readwrite, assign) IBOutlet id<WAImageStackViewDelegate> delegate;
@property (nonatomic, readwrite, assign) WAImageStackViewInteractionState state;
@property (nonatomic, readwrite, retain) NSArray *images;
@property (nonatomic, readwrite, assign) NSUInteger maxNumberOfImages;

@property (nonatomic, readonly, assign) UIView *firstPhotoView;
@property (nonatomic, readonly, assign) BOOL gestureProcessingOngoing;

- (void) setImages:(NSArray *)newImages asynchronously:(BOOL)async withDecodingCompletion:(void(^)(void))aBlock;
- (void) reset;

@end
