//
//  WAFilterPickerViewController.m
//  wammer
//
//  Created by Evadne Wu on 4/20/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFilterPickerViewController.h"

@interface WAFilterPickerViewController ()

@property (nonatomic, readwrite, copy) void(^callback)(NSFetchRequest *);

@end

@implementation WAFilterPickerViewController
@synthesize callback;
@synthesize pickerView;

+ (id) controllerWithCompletion:(void(^)(NSFetchRequest *))block {

	WAFilterPickerViewController *controller = [[self alloc] initWithNibName:nil bundle:nil];
	if (!controller)
		return nil;
	
	controller.callback = block;
	return controller;

}

- (void) viewDidUnload {

	[self setPickerView:nil];
	[super viewDidUnload];

}

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {

	return 1;

}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {

	return 20;

}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {

	return [NSString stringWithFormat:@"%lu %lu", component, row];

}

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {

	NSLog(@"%s %@ %lu %lu", __PRETTY_FUNCTION__, pickerView, row, component);

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
			self.callback(nil);
		
	}];

}

@end
