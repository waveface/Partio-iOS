//
//  WAConnectionStatusView.h
//  wammer
//
//  Created by Shen Steven on 1/30/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAConnectionStatusView : UIView

+ (id) viewFromNib;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *textLabel;

@end
