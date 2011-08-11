//
//  WAImageStackView.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/28/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
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

@property (nonatomic, readwrite, assign) WAImageStackViewInteractionState state;
@property (nonatomic, readwrite, retain) NSArray *files;
@property (nonatomic, readwrite, assign) id<WAImageStackViewDelegate> delegate;
@property (nonatomic, readonly, assign) BOOL gestureProcessingOngoing;

@end
