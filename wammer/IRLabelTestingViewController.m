//
//  IRLabelTestingViewController.m
//  wammer
//
//  Created by Evadne Wu on 10/19/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "IRLabelTestingViewController.h"


@interface IRLabelTestingViewController ()
@property (nonatomic, readwrite, retain) NSTimer *timer;
@end

@implementation IRLabelTestingViewController
@synthesize testLabels;
@synthesize timer;

- (void) viewDidLoad {
	
	[super viewDidLoad];
	
	for (IRLabel *aLabel in self.testLabels) {
	
		aLabel.layer.borderColor = [UIColor redColor].CGColor;
		aLabel.layer.borderWidth = 2.0f;
	
	}
	
}

- (void) viewDidUnload {
	
	self.testLabels = nil;
	[super viewDidUnload];
	
}

- (void) dealloc {

	[timer invalidate];

}

- (void) viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];
	
	self.timer = [NSTimer scheduledTimerWithTimeInterval:0.125 target:self selector:@selector(handleTimerTick:) userInfo:nil repeats:YES];

}

- (void) viewWillDisappear:(BOOL)animated {

	[self.timer invalidate];
	self.timer = nil;
	
	[super viewWillDisappear:animated];

}

- (void) handleTimerTick:(NSTimer *)aTimer {

	NSMutableAttributedString *newString = [[NSMutableAttributedString alloc] initWithString:[[NSDate date] description]];
	NSAttributedString *dotString = [[NSAttributedString alloc] initWithString:@"‡"];
	
	int numberOfDots = (arc4random() % 16) * 4;
	for (int i = 0; i < numberOfDots; i++)
		[newString appendAttributedString:dotString];

	for (IRLabel *aLabel in self.testLabels) {

		aLabel.attributedText = newString;
		[aLabel sizeToFit];
	
	}

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	return YES;
	
}

@end
