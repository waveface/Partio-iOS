//
//  WADripdownMenuViewController.h
//  wammer
//
//  Created by Shen Steven on 10/9/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//


typedef void (^WADripdownMenuCompletionBlock)(void);

#import <UIKit/UIKit.h>

@interface WADripdownMenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

- (id) initWithCompletion:(WADripdownMenuCompletionBlock)completion;
- (IBAction) tapperTapped:(id)sender;

@end
