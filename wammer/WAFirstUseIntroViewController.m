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
@property (nonatomic, strong) UITableViewCell *emailCell;
@property (nonatomic, strong) UITableViewCell *passwordCell;
@property (nonatomic, strong) UITableViewCell *nicknameCell;
@property (nonatomic, strong) UITableViewCell *freePlanCell;
@property (nonatomic, strong) UITableViewCell *premiumPlanCell;
@property (nonatomic, strong) UITableViewCell *ultimatePlanCell;
@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UITextField *nicknameField;
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
	} else {
		self.title = NSLocalizedString(@"INTRODUCTION_TITLE", @"Title on introduction pages");
	}

	self.pageControlUsed = YES;

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
	} else {
		self.title = NSLocalizedString(@"INTRODUCTION_TITLE", @"Title on introduction pages");
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
		if (!self.emailCell) {
			self.emailCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"UITableViewCell"];
			self.emailCell.textLabel.text = NSLocalizedString(@"NOUN_USERNAME", @"Email title in signup page");
			self.emailField = [[UITextField alloc] init];
			self.emailField.font = [UIFont systemFontOfSize:17.0];
			self.emailField.placeholder = NSLocalizedString(@"USERNAME_PLACEHOLDER", @"Email placeholder in signup page");
			self.emailField.delegate = self;
			self.emailField.returnKeyType = UIReturnKeyNext;
			self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
			self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
			self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
			[self.emailCell.contentView addSubview:self.emailField];
			[self.view setNeedsUpdateConstraints];
		}
		return self.emailCell;
	} else if ([indexPath row] == 1) {
		if (!self.premiumPlanCell) {
			self.premiumPlanCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UITableViewCell"];
			self.premiumPlanCell.textLabel.text = NSLocalizedString(@"OPTION_PREMIUM_PLAN", @"Premium plan option in plans page");
			self.premiumPlanCell.detailTextLabel.text = NSLocalizedString(@"PREMIUM_PLAN_DESCRIPTION", @"Premium plan details in plans page");
			[self.view setNeedsUpdateConstraints];
		}
		return self.premiumPlanCell;
		if (!self.passwordCell) {
			self.passwordCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"UITableViewCell"];
			self.passwordCell.textLabel.text = NSLocalizedString(@"NOUN_PASSWORD", @"Password title in signup page");
			self.passwordField = [[UITextField alloc] init];
			self.passwordField.font = [UIFont systemFontOfSize:17.0];
			self.passwordField.secureTextEntry = YES;
			self.passwordField.placeholder = NSLocalizedString(@"PASSWORD_PLACEHOLDER", @"Password placeholder in signup page");
			self.passwordField.delegate = self;
			self.passwordField.returnKeyType = UIReturnKeyNext;
			self.passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
			self.passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
			self.passwordField.keyboardType = UIKeyboardTypeASCIICapable;
			[self.passwordCell.contentView addSubview:self.passwordField];
			[self.view setNeedsUpdateConstraints];
		}
		return self.passwordCell;
	} else if ([indexPath row] == 2) {
		if (!self.ultimatePlanCell) {
			self.ultimatePlanCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UITableViewCell"];
			self.ultimatePlanCell.textLabel.text = NSLocalizedString(@"OPTION_ULTIMATE_PLAN", @"Ultimate plan option in plans page");
			self.ultimatePlanCell.detailTextLabel.text = NSLocalizedString(@"ULTIMATE_PLAN_DESCRIPTION", @"Ultimate plan details in plans page");
			[self.view setNeedsUpdateConstraints];
		}
		return self.ultimatePlanCell;
		if (!self.nicknameCell) {
			self.nicknameCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"UITableViewCell"];
			self.nicknameCell.textLabel.text = NSLocalizedString(@"NOUN_NICKNAME", @"Nickname title in signup page");
			self.nicknameField = [[UITextField alloc] init];
			self.nicknameField.font = [UIFont systemFontOfSize:17.0];
			self.nicknameField.placeholder = NSLocalizedString(@"NICKNAME_PLACEHOLDER", @"Nickname placeholder in signup page");
			self.nicknameField.delegate = self;
			self.nicknameField.returnKeyType = UIReturnKeyGo;
			self.nicknameField.autocorrectionType = UITextAutocorrectionTypeYes;
			self.nicknameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
			[self.nicknameCell.contentView addSubview:self.nicknameField];
			[self.view setNeedsUpdateConstraints];
		}
		return self.nicknameCell;
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
