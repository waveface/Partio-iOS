//
//  WACompositionViewController_SubclassEyesOnly.h
//  wammer
//
//  Created by 冠凱 邱 on 12/5/30.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WACompositionViewController.h"

@interface WACompositionViewController (SubclassEyesOnly)

@property (nonatomic, readonly, copy) void (^completionBlock)(NSURL *returnedURI);

@end
