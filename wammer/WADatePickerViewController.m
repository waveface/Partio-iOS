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
	
	self.datePicker.minimumDate = self.minDate;
	self.datePicker.maximumDate = self.maxDate;

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
