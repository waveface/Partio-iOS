//
//  WAContactPickerViewController.h
//  wammer
//
//  Created by Greener Chen on 13/4/2.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>

@interface WAContactPickerViewController : UIViewController <ABPeoplePickerNavigationControllerDelegate>

- (id)init;
@property (nonatomic, strong) NSMutableArray *members;
@property (nonatomic, copy) void (^onNextHandler)(NSArray *selectedContacts);
@property (nonatomic, copy) void (^onDismissHandler)();

-(IBAction)showContactsPicker:(id)sender;

@end
