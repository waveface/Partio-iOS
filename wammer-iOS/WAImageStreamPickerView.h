//
//  WAImageStreamPickerView.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/22/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Foundation+IRAdditions.h"

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
@property (nonatomic, readwrite, copy) UIView * (^viewForThumbnail)(UIImage *thumbnail);
@property (nonatomic, readwrite, assign) NSUInteger selectedItemIndex;

- (void) reloadData;

@end
