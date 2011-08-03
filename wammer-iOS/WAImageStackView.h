//
//  WAImageStackView.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/28/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>


@class WAImageStackView;


@protocol WAImageStackViewDelegate <NSObject>
- (void) imageStackView:(WAImageStackView *)aStackView didRecognizePinchZoomGestureWithGlobalContentRect:(CGRect)aRect;
@end


@interface WAImageStackView : UIView

@property (nonatomic, readwrite, retain) NSSet *files;
@property (nonatomic, readwrite, assign) id<WAImageStackViewDelegate> delegate;

@end
