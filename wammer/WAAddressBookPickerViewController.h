//
//  WAAddressBookPickerViewController.h
//  wammer
//
//  Created by Greener Chen on 13/4/24.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAAddressBookPickerViewController : UIViewController

@property (nonatomic, copy) void (^onNextHandler)(NSArray *selectedContacts);
@property (nonatomic, copy) void (^onDismissHandler)();

@end
