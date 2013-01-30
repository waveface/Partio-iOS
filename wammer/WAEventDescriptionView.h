//
//  WAEventDescriptionView.h
//  wammer
//
//  Created by kchiu on 13/1/30.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAEventDescriptionView : UIView

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

+ (WAEventDescriptionView *)viewFromNib;

@end
