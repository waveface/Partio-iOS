//
//  WAArticleDateItem.h
//  wammer
//
//  Created by Evadne Wu on 6/28/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAArticleDateItem : UIBarButtonItem

+ (WAArticleDateItem *) instanceFromNib;

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceLabel;

@end
