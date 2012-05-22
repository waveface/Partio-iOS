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

+ (WACompositionViewPhotoCell *) cellRepresentingFile:(WAFile *)aFile reuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic, readwrite, weak) WAFile *representedFile;

@property (nonatomic, readwrite, retain) UIImage *image;
@property (nonatomic, readwrite, copy) void (^onRemove)();

@property (nonatomic, readwrite, assign) BOOL canRemove;	//	Default is YES
@property (nonatomic, readonly, retain) UIImageView *imageContainer;

@property (nonatomic, readwrite, assign) WACompositionViewPhotoCellStyle style;

@end
