//
//  WACollectionPickerViewController.h
//  wammer
//
//  Created by Shen Steven on 3/14/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WACollectionPickerViewController : UITableViewController

+ (id) pickerWithHandler:(void(^)(NSManagedObjectID *selectedCollection))completionBlock onCancel:(void(^)(void))cancelBlock;

- (id) initWithHandler:(void(^)(NSManagedObjectID *selectedCollection))completionBlock;

@end
