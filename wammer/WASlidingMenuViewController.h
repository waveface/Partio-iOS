//
//  WASlidingMenuViewController.h
//  wammer
//
//  Created by Shen Steven on 9/16/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IIViewDeckController.h"

@interface WASlidingMenuViewController : UITableViewController <IIViewDeckControllerDelegate>

@property (nonatomic, weak) id delegate;

@end
