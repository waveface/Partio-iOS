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

@property (nonatomic, readwrite, copy) void (^completionBlock)(void);

@end

@implementation WATutorialViewController
@synthesize scrollView = _scrollView;
@synthesize introductionView = _introductionView;
@synthesize pageControl = _pageControl;
@synthesize startButton = _startButton;
@synthesize completionBlock = _completionBlock;

const CGFloat kScrollObjWidth = 320.0;
const NSUInteger kNumberOfPages = 5;

+ (WATutorialViewController *) controllerWithCompletion:(void(^)(void))completion {

	WATutorialViewController *controller = [self new];
	controller.completionBlock = completion;
	
	return controller;

}

- (void) viewDidLoad {
	
	[super viewDidLoad];
	
	[_scrollView addSubview:self.introductionView];
	
	_scrollView.contentSize = (CGSize){ kNumberOfPages * kScrollObjWidth, CGRectGetHeight(_scrollView.bounds) };
	_scrollView.delegate = self;
	_pageControl.numberOfPages = kNumberOfPages;
	_introductionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"TutorialBackground"]];

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
	
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
	
	self.pageControl.currentPage = floor((aScrollView.contentOffset.x - kScrollObjWidth / 2) / kScrollObjWidth) + 1;
	
}

- (IBAction) enterTimeline:(id)sender {

	if (self.completionBlock) {
		self.completionBlock();
		return;
	}
	
	[(WAAppDelegate_iOS *)[UIApplication sharedApplication].delegate recreateViewHierarchy];
	
}
@end
