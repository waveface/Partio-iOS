//
//  WADatePickerViewController.m
//  wammer
//
//  Created by Evadne Wu on 4/19/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADatePickerViewController.h"

@interface WADatePickerViewController ()

@property (nonatomic, readwrite, copy) void(^callback)(NSDate *);

@end

@implementation WADatePickerViewController
@synthesize callback;
@synthesize datePicker;
@synthesize minDate, maxDate;

+ (id) controllerWithCompletion:(void(^)(NSDate *))block {

	WADatePickerViewController *controller = [[self alloc] initWithNibName:nil bundle:nil];
	if (!controller)
		return nil;
	
	controller.callback = block;
	return controller;

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	/* Programally add UI to make it loaded faster */
	self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4f];

	UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 480, 320, 44)];
	toolbar.barStyle = UIBarStyleBlackTranslucent;
	toolbar.opaque = YES;
	
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(handleCancel:)];
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleDone:)];
	
	toolbar.items = [NSArray arrayWithObjects:cancelButton, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], doneButton, nil];
	
	UIDatePicker *aDatePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 524, 320, 216)];
	aDatePicker.datePickerMode = UIDatePickerModeDate;
	aDatePicker.userInteractionEnabled = YES;
	aDatePicker.hidden = NO;
	aDatePicker.opaque = YES;
	
	aDatePicker.minimumDate = self.minDate;
	aDatePicker.maximumDate = self.maxDate;

	[self.view addSubview:toolbar];
	[self.view addSubview:aDatePicker];
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	
	toolbar.frame = CGRectMake(0, 220, 320, 44);
	aDatePicker.frame = CGRectMake(0, 264, 320, 216);
	
	[UIView commitAnimations];
	
	self.datePicker = aDatePicker;

}

- (void) viewDidUnload {
	
	[self setDatePicker:nil];
	[super viewDidUnload];
	
}

- (IBAction) handlePickerValueChanged:(UIDatePicker *)sender {
	
	//	?
	
}

- (IBAction) handleCancel:(UIBarButtonItem *)sender {

	[self runDismissingAnimationWithCompletion:^{
	
		if (self.callback)
			self.callback(nil);
		
	}];
	
}

- (IBAction) handleDone:(UIBarButtonItem *)sender {

	[self runDismissingAnimationWithCompletion:^{
	
		if (self.callback)
			self.callback(self.datePicker.date);
		
	}];

}

@end
