//
//  WAStatusBar.h
//  wammer
//
//  Created by kchiu on 12/11/15.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAStatusBar : UIWindow

@property (nonatomic, strong) UILabel *syncingLabel;
@property (nonatomic) BOOL isFetching;

@end
