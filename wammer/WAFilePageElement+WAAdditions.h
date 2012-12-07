//
//  WAFilePageElement+WAAdditions.h
//  wammer
//
//  Created by kchiu on 12/12/5.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFilePageElement.h"

@interface WAFilePageElement (WAAdditions)

@property (nonatomic, readonly) UIImage *thumbnailImage;

- (void)cleanImageCache;

@end
