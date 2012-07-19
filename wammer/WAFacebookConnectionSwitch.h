//
//  WAFacebookConnectionSwitch.h
//  wammer
//
//  Created by Evadne Wu on 7/18/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WAFacebookInterface;
@interface WAFacebookConnectionSwitch : UISwitch

@property (nonatomic, readwrite, weak) WAFacebookInterface *facebookInterface;

@end
