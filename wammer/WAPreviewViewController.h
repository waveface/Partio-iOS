//
//  WAPreviewViewController.h
//  wammer
//
//  Created by jamie on 2/15/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAPreviewViewController : UIViewController

@property (retain, nonatomic) IBOutlet UIButton *deleteButton;
@property (retain, nonatomic) IBOutlet UINavigationBar *navigationBar;

- (IBAction)handleDoneTap:(id)sender;

@end
