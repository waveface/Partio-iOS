//
//  WACalendarPickerByTypeViewController.m
//  wammer
//
//  Created by Greener Chen on 12/11/21.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WACalendarPickerByTypeViewController.h"


@interface WACalendarPickerByTypeViewController ()

@property (nonatomic, readwrite, copy) void(^callback)(NSDate *);

@end

@implementation WACalendarPickerByTypeViewController

- (void) didMoveToParentViewController:(UIViewController *)parent {
	
	[super didMoveToParentViewController:parent];
	
	[self runPresentingAnimationWithCompletion:nil];
	
}

- (void) runPresentingAnimationWithCompletion:(void(^)(void))block {
	
	CGRect containerToRect = self.containerView.frame;
	CGRect containerFromRect = CGRectOffset(containerToRect, 0, CGRectGetHeight(containerToRect));
	
	self.backdropView.alpha = 0;
	self.containerView.frame = containerFromRect;
	
	[UIView animateWithDuration:0.3 animations:^{
		
		self.backdropView.alpha = 1;
		self.containerView.frame = containerToRect;
		
	} completion:^(BOOL finished) {
		
		if (block)
			block();
		
	}];
	
}

- (void) runDismissingAnimationWithCompletion:(void(^)(void))block {
	
	CGRect containerFromRect = self.containerView.frame;
	CGRect containerToRect = CGRectOffset(containerFromRect, 0, CGRectGetHeight(containerFromRect));
	
	self.backdropView.alpha = 1;
	self.containerView.frame = containerFromRect;
	
	[UIView animateWithDuration:0.3 animations:^{
		
		self.backdropView.alpha = 0;
		self.containerView.frame = containerToRect;
		
	} completion:^(BOOL finished) {
		
		if (block)
			block();
		
	}];
	
}

+ (id) controllerWithCompletion:(void(^)(NSDate *))block {
	
	WACalendarPickerByTypeViewController *controller = [[self alloc] initWithNibName:nil bundle:nil];
	if (!controller)
		return nil;
	
	controller.callback = block;
	return controller;
	
}

- (void)handleCancel:(UIButton *)sender
{
	[self runDismissingAnimationWithCompletion:^{
		if (self.callback)
			self.callback(nil);
	}];
}

- (void)handleDone:(UIButton *)sender
{
	[self runDismissingAnimationWithCompletion:^{
		if (self.callback)
			self.callback(self.datePicker.selectedDate);
	}];
}


- (void)viewDidLoad
{
	[super viewDidLoad];

	self.view.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.4f];

	UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
	cancelButton.frame = CGRectMake(0, 0, 320, 120);
	[cancelButton addTarget:self action:@selector(handleCancel:) forControlEvents:UIControlEventTouchUpInside];

	UIButton *doneButton = self.doneButton;
	doneButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	doneButton.frame = CGRectMake(263, 105, 55, 24);
	[doneButton setTitle:NSLocalizedString(@"DONE", nil) forState:UIControlStateNormal];
	doneButton.titleLabel.font = [UIFont systemFontOfSize:10.f];
	[doneButton setBackgroundColor:[UIColor clearColor]];
  doneButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
  doneButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	[doneButton addTarget:self action:@selector(handleDone:) forControlEvents:UIControlEventTouchUpInside];

	[self.view addSubview:cancelButton];

	
  KalViewController *calPicker = [[KalViewController alloc] init];
	calPicker.delegate = self;
  UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:calPicker];
  
	// Hide navigation bar if not all types
	[navController setNavigationBarHidden:YES];
  
	navController.view.frame = CGRectMake(0, 100, 320, 550);
  [self addChildViewController:navController];
  [self.view addSubview:navController.view];
	[self.view addSubview:doneButton];
	
  [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView commitAnimations];
	
	self.datePicker = calPicker;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
