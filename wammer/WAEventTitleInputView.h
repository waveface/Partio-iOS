//
//  WAEventTitleInputView.h
//  wammer
//
//  Created by Shen Steven on 5/17/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAEventTitleInputView : UIToolbar

@property (nonatomic, weak) IBOutlet UITextField *inputField;

+ (id) viewFromNib;

@property (nonatomic, copy) void (^onTitleChange)(NSString *newTitle);

@end
