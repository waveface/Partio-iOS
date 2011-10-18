//
//  WAImageStreamPickerView.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/22/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "Foundation+IRAdditions.h"

#ifndef __WAImageStreamPickerView__
#define __WAImageStreamPickerView__

enum {
	WADynamicThumbnailsStyle = 0,
	WAClippedThumbnailsStyle
}; typedef NSUInteger WAImageStreamPickerViewStyle;

#endif


@class WAImageStreamPickerView;
@protocol WAImageStreamPickerViewDelegate <NSObject>

- (NSUInteger) numberOfItemsInImageStreamPickerView:(WAImageStreamPickerView *)picker;
- (id) itemAtIndex:(NSUInteger)anIndex inImageStreamPickerView:(WAImageStreamPickerView *)picker;

- (UIImage *) thumbnailForItem:(id)anItem inImageStreamPickerView:(WAImageStreamPickerView *)picker;
- (void) imageStreamPickerView:(WAImageStreamPickerView *)picker didSelectItem:(id)anItem;

@end


@interface WAImageStreamPickerView : UIView

@property (nonatomic, readwrite, assign) id<WAImageStreamPickerViewDelegate> delegate;
@property (nonatomic, readwrite, assign) UIEdgeInsets edgeInsets;
@property (nonatomic, readwrite, retain) UIView *activeImageOverlay;
@property (nonatomic, readwrite, copy) UIView * (^viewForThumbnail)(UIView *existingView, UIImage *thumbnail);
@property (nonatomic, readwrite, assign) NSUInteger selectedItemIndex;

@property (nonatomic, readwrite, assign) WAImageStreamPickerViewStyle style;	//	Defaults to WADynamicThumbnailStyle

@property (nonatomic, readwrite, assign) CGFloat thumbnailSpacing; // Defaults to 4.0f 

@property (nonatomic, readwrite, assign) CGFloat thumbnailAspectRatio;	//	Defaults to 1.  The aspect ratio of the thumbnail is only used when the image stream picker’s style is set to WAClippedThumbnailsStyle; otherwise, the ratio will be calculated from the actual images.

- (void) reloadData;

@end
