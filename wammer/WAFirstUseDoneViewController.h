//
//  WAFirstUseDoneViewController.h
//  wammer
//
//  Created by kchiu on 12/10/24.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAFirstUseDoneViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *doneButton;

- (IBAction)handleDone:(id)sender;

@end
