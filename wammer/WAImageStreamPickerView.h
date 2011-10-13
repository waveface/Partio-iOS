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

//	#ifndef __WAImageStreamPickerView__
//	#define __WAImageStreamPickerView__
//
//	enum {
//		WAImageStreamPickerViewStyleDynamicSizes = 0,
//	}; typedef NSUInteger WAImageStreamPickerViewStyle;
//
//	#endif


@class WAImageStreamPickerView;
@protocol WAImageStreamPickerViewDelegate <NSObject>

- (NSUInteger) numberOfItemsInImageStreamPickerView:(WAImageStreamPickerView *)picker;
- (id) itemAtIndex:(NSUInteger)anIndex inImageStreamPickerView:(WAImageStreamPickerView *)picker;

- (UIImage *) thumbnailForItem:(id)anItem inImageStreamPickerView:(WAImageStreamPickerView *)picker;
- (void) imageStreamPickerView:(WAImageStreamPickerView *)picker didSelectItem:(id)anItem;

@end


@interface WAImageStreamPickerView : UIView

@property (nonatomic, readwrite, assign) CGFloat minAspectRatio;
@property (nonatomic, readwrite, assign) CGFloat maxAspectRatio;
@property (nonatomic, readwrite, copy) NSString *thumbnailContentsGravity;

@property (nonatomic, readwrite, assign) id<WAImageStreamPickerViewDelegate> delegate;
@property (nonatomic, readwrite, assign) UIEdgeInsets edgeInsets;
@property (nonatomic, readwrite, retain) UIView *activeImageOverlay;
@property (nonatomic, readwrite, copy) UIView * (^viewForThumbnail)(UIImage *thumbnail);
@property (nonatomic, readwrite, assign) NSUInteger selectedItemIndex;

- (void) reloadData;

@end
