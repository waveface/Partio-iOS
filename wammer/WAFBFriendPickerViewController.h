//
//  WAFBFriendPickerViewController.h
//  wammer
//
//  Created by Greener Chen on 13/5/13.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FBFriendPickerViewController.h>

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

@interface WAFBFriendPickerViewController : FBFriendPickerViewController

@property (nonatomic, copy) NSSet *extraFieldsForFriendRequest;
@property (nonatomic, strong) NSMutableArray *members;

@property (nonatomic, copy) void (^onNextHandler)(NSArray *selectedContacts);
@property (nonatomic, copy) void (^onDismissHandler)();

@end
