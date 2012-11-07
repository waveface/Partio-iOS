//
//  WAFirstUseFacebookLoginView.h
//  wammer
//
//  Created by kchiu on 12/11/6.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAFirstUseFacebookLoginView : UIView

@property (weak, nonatomic) IBOutlet UIButton *facebookLoginButton;

+ (WAFirstUseFacebookLoginView *)viewFromNib;

@end
