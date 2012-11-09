//
//  WAFirstUseIntroViewController.m
//  wammer
//
//  Created by kchiu on 12/10/29.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFirstUseIntroViewController.h"
#import "WADefines.h"

@interface WAFirstUseIntroViewController ()

@property (nonatomic, strong) NSArray *pages;
@property (nonatomic, strong) UITableViewCell *freePlanCell;
@property (nonatomic, strong) UITableViewCell *premiumPlanCell;
@property (nonatomic, strong) UITableViewCell *ultimatePlanCell;
@property (nonatomic) BOOL pageControlUsed;
@property (nonatomic, strong) UITableView *plansPage;
@property (nonatomic) BOOL isKeyboardShown;

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
	self.pageControl.currentPage = 0;

	self.title = NSLocalizedString(@"INTRODUCTION_TITLE", @"Title on introduction pages");

	self.plansPage = [self.pages lastObject];
	self.plansPage.dataSource = self;
	self.plansPage.delegate = self;

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

#pragma mark UITableView delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	return 3;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	if ([indexPath row] == 0) {
		if (!self.freePlanCell) {
			self.freePlanCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UITableViewCell"];
			self.freePlanCell.textLabel.text = NSLocalizedString(@"OPTION_FREE_PLAN", @"Free plan option in plans page");
			self.freePlanCell.detailTextLabel.text = NSLocalizedString(@"FREE_PLAN_DESCRIPTION", @"Free plan details in plans page");
			self.freePlanCell.accessoryType = UITableViewCellAccessoryCheckmark;
			[self.view setNeedsUpdateConstraints];
		}
		return self.freePlanCell;
	} else if ([indexPath row] == 1) {
		if (!self.premiumPlanCell) {
			self.premiumPlanCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UITableViewCell"];
			self.premiumPlanCell.textLabel.text = NSLocalizedString(@"OPTION_PREMIUM_PLAN", @"Premium plan option in plans page");
			self.premiumPlanCell.detailTextLabel.text = NSLocalizedString(@"PREMIUM_PLAN_DESCRIPTION", @"Premium plan details in plans page");
			[self.view setNeedsUpdateConstraints];
		}
		return self.premiumPlanCell;
	} else if ([indexPath row] == 2) {
		if (!self.ultimatePlanCell) {
			self.ultimatePlanCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UITableViewCell"];
			self.ultimatePlanCell.textLabel.text = NSLocalizedString(@"OPTION_ULTIMATE_PLAN", @"Ultimate plan option in plans page");
			self.ultimatePlanCell.detailTextLabel.text = NSLocalizedString(@"ULTIMATE_PLAN_DESCRIPTION", @"Ultimate plan details in plans page");
			[self.view setNeedsUpdateConstraints];
		}
		return self.ultimatePlanCell;
	}

	return nil;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *hitCell = [tableView cellForRowAtIndexPath:indexPath];
	
	self.freePlanCell.accessoryType = UITableViewCellAccessoryNone;
	self.premiumPlanCell.accessoryType = UITableViewCellAccessoryNone;
	self.ultimatePlanCell.accessoryType = UITableViewCellAccessoryNone;
	
	hitCell.accessoryType = UITableViewCellAccessoryCheckmark;
	
	if (hitCell == self.freePlanCell) {
		[[NSUserDefaults standardUserDefaults] setInteger:WABusinessPlanFree forKey:kWABusinessPlan];
	} else if (hitCell == self.premiumPlanCell) {
		[[NSUserDefaults standardUserDefaults] setInteger:WABusinessPlanPremium forKey:kWABusinessPlan];
	} else if (hitCell == self.ultimatePlanCell) {
		[[NSUserDefaults standardUserDefaults] setInteger:WABusinessPlanUltimate forKey:kWABusinessPlan];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

}

@end
