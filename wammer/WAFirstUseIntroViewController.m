//
//  WAFirstUseIntroViewController.m
//  wammer
//
//  Created by kchiu on 12/10/29.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseIntroViewController.h"
#import "WADefines.h"
#import "WAAppearance.h"
#import "WADataPlanViewController.h"

@interface WAFirstUseIntroViewController ()

@property (nonatomic, strong) NSArray *pages;
@property (nonatomic, strong) UITableViewCell *freePlanCell;
@property (nonatomic, strong) UITableViewCell *premiumPlanCell;
@property (nonatomic, strong) UITableViewCell *ultimatePlanCell;
@property (nonatomic) BOOL pageControlUsed;
@property (nonatomic, strong) UITableView *plansPage;
@property (nonatomic) BOOL isKeyboardShown;
@property (nonatomic) WADataPlanViewController *dataPlanController;

@end

// The pagination effect refers sample codes from PageControl in iOS developer library
// Ref: http://developer.apple.com/library/ios/#samplecode/PageControl/Introduction/Intro.html
@implementation WAFirstUseIntroViewController

- (void)viewDidLoad {

	[super viewDidLoad];

	self.pages = [[UINib nibWithNibName:@"WAFirstUseIntroView" bundle:[NSBundle mainBundle]] instantiateWithOwner:nil options:nil];
	for (UIView *page in self.pages) {
    [self.scrollView addSubview:page];
	}
	self.scrollView.delegate = self;

	self.pageControl.numberOfPages = [self.pages count];
  [self.pageControl setPageIndicatorTintColor:[UIColor darkGrayColor]];
	self.pageControl.currentPage = 0;

	self.title = NSLocalizedString(@"INTRODUCTION_TITLE", @"Title on introduction pages");

  self.dataPlanController = [[WADataPlanViewController alloc] initWithStyle:UITableViewStyleGrouped];
	self.plansPage = [self.pages lastObject];
	self.plansPage.dataSource = self.dataPlanController;
	self.plansPage.delegate = self.dataPlanController;

	__weak WAFirstUseIntroViewController *wSelf = self;
	self.navigationItem.leftBarButtonItem = (UIBarButtonItem *)WABackBarButtonItem([UIImage imageNamed:@"back"], @"", ^{
		[wSelf.navigationController popViewControllerAnimated:YES];
	});

}

- (void)viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];

	self.navigationController.navigationBar.alpha = 1.0f;

	__weak WAFirstUseIntroViewController *wSelf = self;
	[self.pages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		CGRect frame = wSelf.view.frame;
		frame.origin.x = frame.size.width * idx;
		frame.origin.y = 0;
		UIView *view = obj;
		view.frame = frame;
	}];

}

- (void)viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];

	// Set scrollView's contentSize only works here if auto-layout is enabled
	// Ref: http://stackoverflow.com/questions/12619786/embed-imageview-in-scrollview-with-auto-layout-on-ios-6
	self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * [self.pages count], self.scrollView.frame.size.height);

}

#pragma mark Target actions

- (IBAction)handleChangePage:(id)sender {

	NSInteger page = self.pageControl.currentPage;
	CGRect frame = self.scrollView.frame;
	frame.origin.x = frame.size.width * page;
	frame.origin.y = 0;
	[self.scrollView scrollRectToVisible:frame animated:YES];

	if (page == [self.pages count]-1) {
		self.title = NSLocalizedString(@"PLANS_CONTROLLER_TITLE", @"Title of view controller choosing plans");
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"SIGN_UP_BAR_BUTTON_TITLE", @"Title of bar button going sign up page") style:UIBarButtonItemStyleBordered target:self action:@selector(handleGotoSignUpPage:)];
	} else {
		self.title = NSLocalizedString(@"INTRODUCTION_TITLE", @"Title on introduction pages");
		self.navigationItem.rightBarButtonItem = nil;
	}

	self.pageControlUsed = YES;

}

- (void)handleGotoSignUpPage:(id)sender {

	[self performSegueWithIdentifier:@"WASegueIntroToSignUp" sender:sender];

}

#pragma mark UIScrollView delegates

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

	if (self.isKeyboardShown) {
		// disable horizontal scrolling
		[scrollView setContentOffset:CGPointMake(self.view.frame.size.width * ([self.pages count]-1), scrollView.contentOffset.y)];
		return;
	}
	
	if (self.pageControlUsed) {
		return;
	}

	CGFloat pageWidth = self.scrollView.frame.size.width;
	NSInteger page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	self.pageControl.currentPage = page;

	if (page == [self.pages count]-1) {
		self.title = NSLocalizedString(@"PLANS_CONTROLLER_TITLE", @"Title of view controller choosing plans");
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"SIGN_UP_BAR_BUTTON_TITLE", @"Title of bar button going sign up page") style:UIBarButtonItemStyleBordered target:self action:@selector(handleGotoSignUpPage:)];
	} else {
		self.title = NSLocalizedString(@"INTRODUCTION_TITLE", @"Title on introduction pages");
		self.navigationItem.rightBarButtonItem = nil;
	}

}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {

	self.pageControlUsed = NO;

}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

	self.pageControlUsed = NO;

}

@end
