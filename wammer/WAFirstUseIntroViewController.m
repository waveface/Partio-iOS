//
//  WAFirstUseIntroViewController.m
//  wammer
//
//  Created by kchiu on 12/10/29.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseIntroViewController.h"
#import "WAFirstUseSignUpView.h"

@interface WAFirstUseIntroViewController ()

@property (nonatomic, readwrite, strong) NSArray *pages;
@property (nonatomic, readwrite) BOOL pageControlUsed;

@end

// The implementation is refering sample codes from PageControl in iOS developer library
// Ref: http://developer.apple.com/library/ios/#samplecode/PageControl/Introduction/Intro.html
@implementation WAFirstUseIntroViewController

- (void)viewDidLoad {

	[super viewDidLoad];

	self.pages = [[UINib nibWithNibName:@"WAFirstUseIntroView" bundle:[NSBundle mainBundle]] instantiateWithOwner:nil options:nil];

	__weak WAFirstUseIntroViewController *wSelf = self;
	[self.pages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		CGRect frame = wSelf.view.frame;
		frame.origin.x = frame.size.width * idx;
		frame.origin.y = 0;
		UIView *view = obj;
		view.frame = frame;
		[wSelf.scrollView addSubview:view];
	}];

	self.pageControl.numberOfPages = [self.pages count];
	self.pageControl.currentPage = 0;
	
	self.scrollView.delegate = self;
	
	WAFirstUseSignUpView *signupView = [self.pages lastObject];
	[signupView.facebookSignupButton addTarget:self action:@selector(handleFacebookSignup:) forControlEvents:UIControlEventTouchUpInside];
	[signupView.emailSignupButton addTarget:self action:@selector(handleEmailSignup:) forControlEvents:UIControlEventTouchUpInside];

}

- (void)viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];

	self.navigationController.navigationBar.alpha = 1.0f;

}

- (void)viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];

	// Set scrollView's contentSize only works here if auto-layout is enabled
	// Ref: http://stackoverflow.com/questions/12619786/embed-imageview-in-scrollview-with-auto-layout-on-ios-6
	self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * [self.pages count], self.scrollView.frame.size.height);

}

- (IBAction)handleChangePage:(id)sender {

	NSInteger page = self.pageControl.currentPage;
	CGRect frame = self.scrollView.frame;
	frame.origin.x = frame.size.width * page;
	frame.origin.y = 0;
	[self.scrollView scrollRectToVisible:frame animated:YES];

	self.pageControlUsed = YES;

}

- (void)handleFacebookSignup:(id)sender {

	NSLog(@"sign up via facebook");

}

- (void)handleEmailSignup:(id)sender {

	NSLog(@"sign up via email");

}

#pragma mark UIScrollView delegates

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

	if (self.pageControlUsed) {
		return;
	}

	CGFloat pageWidth = self.scrollView.frame.size.width;
	NSInteger page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	self.pageControl.currentPage = page;

}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {

	self.pageControlUsed = NO;

}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

	self.pageControlUsed = NO;

}

@end
