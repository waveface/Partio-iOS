//
//  WACompositionViewPhotoCell.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/11/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "AQGridViewCell.h"
#import "WADataStore.h"

@interface WACompositionViewPhotoCell : AQGridViewCell

+ (WACompositionViewPhotoCell *) cellRepresentingFile:(WAFile *)aFile reuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic, readwrite, retain) UIImage *image;
@property (nonatomic, readwrite, copy) void (^onRemove)();

@end
