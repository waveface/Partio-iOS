//
//  WATutorialViewController.m
//  wammer
//
//  Created by jamie on 7/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WATutorialViewController.h"

@interface WATutorialViewController ()

@end

@implementation WATutorialViewController
@synthesize scrollView;

const CGFloat kScrollObjWidth = 320.0;
const NSUInteger kNumberOfPages = 3;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// load images
	CGFloat x = 0;
	
	for (NSUInteger i = 1; i <= kNumberOfPages; i++) {
		NSString *imageName = [NSString stringWithFormat:@"TutorialPage%d", i];
		UIImage *image = [UIImage imageNamed:imageName];
		UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
		CGRect frame = imageView.frame;
		frame.origin = (CGPoint){x, 0};
		imageView.frame = frame;
		
		x += kScrollObjWidth;
		[scrollView addSubview:imageView];
	}
	[scrollView setContentSize:(CGSize){kNumberOfPages*kScrollObjWidth, [scrollView bounds].size.height}];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidUnload {
	[self setScrollView:nil];
	[super viewDidUnload];
}
@end
