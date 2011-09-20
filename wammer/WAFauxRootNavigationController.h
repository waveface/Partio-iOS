//
//  WAFauxRootNavigationController.h
//  wammer
//
//  Created by Evadne Wu on 9/19/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAFauxRootNavigationController : UINavigationController

@property (nonatomic, readwrite, copy) void (^onPoppingFauxRoot)();

@end
