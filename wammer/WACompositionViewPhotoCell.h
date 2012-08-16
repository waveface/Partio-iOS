//
//  WACompositionViewPhotoCell.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/11/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "AQGridViewCell.h"
#import "WADataStore.h"


enum {
	
	WACompositionViewPhotoCellShadowedStyle = 0,
	WACompositionViewPhotoCellBorderedPlainStyle,
	WACompositionViewPhotoCellDefaultStyle = WACompositionViewPhotoCellShadowedStyle
	
}; typedef NSUInteger WACompositionViewPhotoCellStyle;


@interface WACompositionViewPhotoCell : AQGridViewCell

+ (WACompositionViewPhotoCell *) cellWithReusingIdentifier:(NSString *)identifier;

@property (nonatomic, readwrite, assign) BOOL canRemove;	//	Default is YES
@property (nonatomic, readwrite, assign) WACompositionViewPhotoCellStyle style;

@property (nonatomic, readwrite, strong) UIImage *image;

@property (nonatomic, readonly, strong) UIImageView *imageContainer;
@property (nonatomic, readwrite, copy) void (^onRemove)();

@end
