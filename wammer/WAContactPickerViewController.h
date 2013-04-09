//
//  WAContactPickerViewController.h
//  wammer
//
//  Created by Greener Chen on 13/4/2.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>

@interface WAContactPickerViewController : UITableViewController <ABPeoplePickerNavigationControllerDelegate>

@property (nonatomic, strong) NSMutableArray *members;
@property (copy) void (^onNextHandler)(NSArray *selectedContacts);

-(IBAction)showContactsPicker:(id)sender;

@end
