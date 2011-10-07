//
//  WANavigationController.h
//  wammer
//
//  Created by Evadne Wu on 10/7/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WANavigationController : UINavigationController

@property (nonatomic, readwrite, copy) void (^onViewDidLoad)(WANavigationController *self);

@end
