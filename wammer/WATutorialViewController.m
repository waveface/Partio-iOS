//
//  WATutorialViewController.m
//  wammer
//
//  Created by jamie on 7/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WATutorialViewController.h"
#import "WAAppDelegate_iOS.h"

@interface WATutorialViewController ()

@end

@implementation WATutorialViewController
@synthesize scrollView;
@synthesize introductionView;
@synthesize pageControl;
@synthesize startButton;

const CGFloat kScrollObjWidth = 320.0;
const NSUInteger kNumberOfPages = 5;

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
	[scrollView addSubview:self.introductionView];

	[scrollView setContentSize:(CGSize){kNumberOfPages*kScrollObjWidth, [scrollView bounds].size.height}];
	scrollView.delegate = self;
	pageControl.numberOfPages = kNumberOfPages;
	introductionView.backgroundColor =  [UIColor colorWithPatternImage:[UIImage imageNamed:@"TutorialBackground"]];

	
	if( [pageControl respondsToSelector:@selector(setPageIndicatorTintColor:)] ){
		[[UIPageControl appearance] performSelector:@selector(setPageIndicatorTintColor:) withObject: [UIColor colorWithRed:0.17 green:0.19 blue:0.21 alpha:0.9]];
		[[UIPageControl appearance] performSelector:@selector(setCurrentPageIndicatorTintColor:) withObject:[UIColor colorWithRed:0.31	green:0.54 blue:0.58 alpha:1]];
	}

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
	[self setPageControl:nil];
	[self setStartButton:nil];
	[super viewDidUnload];
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
	int page = floor((aScrollView.contentOffset.x - kScrollObjWidth / 2) / kScrollObjWidth) + 1;
	
	self.pageControl.currentPage = page;
}

- (IBAction)enterTimeline:(id)sender {
	WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS *)[UIApplication sharedApplication].delegate;
	[appDelegate recreateViewHierarchy];
}
@end
