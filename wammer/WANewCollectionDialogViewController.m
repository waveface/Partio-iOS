//
//  WANewCollectionDialogViewController.m
//  wammer
//
//  Created by Shen Steven on 3/13/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WANewCollectionDialogViewController.h"

@interface WANewCollectionDialogViewController () <UIAlertViewDelegate>
@property (nonatomic, copy) void (^completionBlock)(NSString*);
@end

@implementation WANewCollectionDialogViewController

- (id) initWithCompletionBlock:(void(^)(NSString*))completionBlock {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    UIAlertView *alertForName = [[UIAlertView alloc] initWithTitle:@"Collection Name"
                                                           message:@""
                                                          delegate:self
                                                 cancelButtonTitle:@"Cancel"
                                                 otherButtonTitles:@"Create", nil];
    alertForName.alertViewStyle = UIAlertViewStylePlainTextInput;
    self.completionBlock = completionBlock;
    self.view = alertForName;
  }
  return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void) viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [(UIAlertView*)self.view show];
}

- (void) viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  NSString *collectionName = [alertView textFieldAtIndex:0].text;
  
  if (self.completionBlock)
    self.completionBlock(collectionName);
  
}

@end
