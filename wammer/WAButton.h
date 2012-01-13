//
//  WAButton.h
//  wammer
//
//  Created by Evadne Wu on 1/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAButton : UIButton

@property (nonatomic, readwrite, copy) void (^action)(void);

@end
