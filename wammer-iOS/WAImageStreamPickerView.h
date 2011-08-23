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

- (void) imageStreamPickerView:(WAImageStreamPickerView *)picker didSelectItem:(id)anItem;
- (UIImage *) thumbnailForItem:(id)anItem inImageStreamPickerView:(WAImageStreamPickerView *)picker;
- (NSUInteger) numberOfItemsInImageStreamPickerView:(WAImageStreamPickerView *)picker;
- (id) itemInImageStreamPickerView:(WAImageStreamPickerView *)picker;

@end


@interface WAImageStreamPickerView : UIView

@property (nonatomic, readwrite, assign) id<WAImageStreamPickerViewDelegate> delegate;
@property (nonatomic, readwrite, assign) UIEdgeInsets edgeInsets;
@property (nonatomic, readwrite, retain) UIView *activeImageOverlay;

- (void) reloadData;

@end
