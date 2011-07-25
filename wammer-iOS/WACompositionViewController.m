//
//  WACompositionViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WACompositionViewController.h"


@interface WACompositionViewController ()
@property (nonatomic, readwrite, retain) UISegmentedControl *contentToggle;
@end


@implementation WACompositionViewController
@synthesize contentToggle;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self)
		return nil;
	
	self.title = @"Compose";
		
	return self;

}

- (void) loadView {

	self.view = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.view.backgroundColor = [UIColor whiteColor];
	
	UILabel *descriptionLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
	descriptionLabel.textAlignment = UITextAlignmentCenter;
	descriptionLabel.font = [UIFont boldSystemFontOfSize:18.0f];
	descriptionLabel.text = NSStringFromClass([self class]);
	[descriptionLabel sizeToFit];
	
	descriptionLabel.center = self.view.center;
	
	[self.view addSubview:descriptionLabel];
	
	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(handleCancel:)] autorelease];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleDone:)] autorelease];
	
	self.contentToggle = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
		@"Compose",
		@"Preview",
	nil]];
	
	self.contentToggle.segmentedControlStyle = UISegmentedControlStyleBar;
	
	[self.contentToggle setSelectedSegmentIndex:0];
	[self.contentToggle sizeToFit];
	
	self.navigationItem.titleView = self.contentToggle;

}

- (void) handleDone:(UIBarButtonItem *)sender {

	[self dismissModalViewControllerAnimated:YES];

}

- (void) handleCancel:(UIBarButtonItem *)sender {

	[self dismissModalViewControllerAnimated:YES];

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	return YES;
	
}

@end
