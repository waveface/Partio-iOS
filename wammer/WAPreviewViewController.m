//
//  WAPreviewViewController.m
//  wammer
//
//  Created by jamie on 2/15/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAPreviewViewController.h"

@implementation WAPreviewViewController
@synthesize deleteButton;
@synthesize navigationBar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"composeBackground"]];
		
		UIButton *button = self.deleteButton;
		button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
		
		UIImage *normal = [[UIImage imageNamed:@"delete"] stretchableImageWithLeftCapWidth:5 topCapHeight:0];
		[button setBackgroundImage:normal forState:UIControlStateNormal];
		[button setBackgroundColor:[UIColor clearColor]];
		UIImage *highlight = [[UIImage imageNamed:@"deletepressed"] stretchableImageWithLeftCapWidth:5 topCapHeight:0];
		[button setBackgroundImage:highlight forState:UIControlStateHighlighted];
		button.titleLabel.shadowColor = [UIColor lightGrayColor];
		button.titleLabel.shadowOffset = CGSizeMake(0, -1);
				
		UIImageView *background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"navigationBar"]];
		
		self.navigationBar.tintColor = [UIColor brownColor];
		[self.navigationBar insertSubview:background atIndex:1];
}

- (void)viewDidUnload
{
	[self setDeleteButton:nil];
	[self setNavigationBar:nil];
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
	[deleteButton release];
	[navigationBar release];
	[navigationBar release];
	[super dealloc];
}

- (UIButton *)buttonWithFrame:(CGRect)frame normalImage:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage disabledImage:(UIImage *)disabledImage target:(id)target selector:(SEL)inSelector {
	UIButton *button = [[UIButton alloc] initWithFrame:frame];
	button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    
    // Image for normal state
	UIImage *newNormalImage = [normalImage stretchableImageWithLeftCapWidth:10 topCapHeight:10];
	[button setBackgroundImage:newNormalImage forState:UIControlStateNormal];
    
    // Image for highlighted state
	UIImage *newHighlightedImage = [highlightedImage stretchableImageWithLeftCapWidth:10 topCapHeight:10];
	[button setBackgroundImage:newHighlightedImage forState:UIControlStateHighlighted];
    
    // Image for disabled state
    UIImage *newDisabledImage = [disabledImage stretchableImageWithLeftCapWidth:10 topCapHeight:10];
	[button setBackgroundImage:newDisabledImage forState:UIControlStateDisabled];
    
	[button addTarget:target action:inSelector forControlEvents:UIControlEventTouchUpInside];
    button.adjustsImageWhenDisabled = YES;
    button.adjustsImageWhenHighlighted = YES;
	[button setBackgroundColor:[UIColor clearColor]];	// in case the parent view draws with a custom color or gradient, use a transparent color
    [button autorelease];
    return button;
}

- (IBAction)handleDoneTap:(id)sender {
	//save preview selection
	[self dismissModalViewControllerAnimated:YES];
}
@end
