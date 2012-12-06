//
//  WACalendarPickerByTypeViewController.m
//  wammer
//
//  Created by Greener Chen on 12/11/21.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WACalendarPickerViewController.h"
#import "WACalendarPickerDataSource.h"
#import "WAEventViewController.h"
#import "WADayViewController.h"
#import "WANavigationController.h"
#import "WAAppearance.h"

@interface WACalendarPickerViewController ()
{
	WANavigationController *calNavController;
	id dataSource;
	UITableView *tableView;
	WAArticle *selectedEvent;
	Class containedClass;
}

@property (nonatomic, readwrite, copy) void(^callback)(NSDate *);

@end

@implementation WACalendarPickerViewController


- (id) initWithClassNamed:(Class)aClass {
	self = [self initWithNibName:nil bundle:nil];
	containedClass = aClass;
	return self;
}

- (void) didMoveToParentViewController:(UIViewController *)parent {
	
	[super didMoveToParentViewController:parent];
	
	[self runPresentingAnimationWithCompletion:nil];
	
}

- (void) runPresentingAnimationWithCompletion:(void(^)(void))block {
	
	CGRect containerToRect = self.containerView.frame;
	CGRect containerFromRect = CGRectOffset(containerToRect, 0, CGRectGetHeight(containerToRect));
	
	self.backdropView.alpha = 0;
	self.containerView.frame = containerFromRect;
	
	[UIView animateWithDuration:0.5 animations:^{
		
		self.backdropView.alpha = 1;
		self.containerView.frame = containerToRect;
		
	} completion:^(BOOL finished) {
		
		if (block)
			block();
		
	}];
	
}

- (void) runDismissingAnimationWithCompletion:(void(^)(void))block {
	
	CGRect containerFromRect = self.containerView.frame;
	CGRect containerToRect = CGRectOffset(containerFromRect, 0, CGRectGetHeight(containerFromRect));
	
	self.backdropView.alpha = 1;
	self.containerView.frame = containerFromRect;
	
	[UIView animateWithDuration:0.5 animations:^{
		
		self.backdropView.alpha = 0;
		self.containerView.frame = containerToRect;
		
	} completion:^(BOOL finished) {
		
		if (block)
			block();
		
	}];
	
}

+ (id) controllerWithCompletion:(callbackBlock)block {
	
	WACalendarPickerViewController *controller = [[self alloc] initWithNibName:nil bundle:nil];
	if (!controller)
		return nil;
	
	controller.callback = [block copy];
	return controller;
	
}

- (void)handleCancel:(UIButton *)sender
{
	[self runDismissingAnimationWithCompletion:^{
		if (self.callback)
			self.callback(nil);
	}];
}

- (void)handleDone:(UIButton *)sender
{
	[self runDismissingAnimationWithCompletion:^{
		if (self.callback)
			// add time interval to 23:59
			self.callback([[self.calPicker selectedDate] dateByAddingTimeInterval:86399]);
	}];
}

- (void) handleSelectToday
{
	[_calPicker showAndSelectDate:[NSDate date]];
}


- (void)viewDidLoad
{
	[super viewDidLoad];
	
	//self.view.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.4f];

  _calPicker = [[KalViewController alloc] init];
	_calPicker.title = NSLocalizedString(@"CALENDAR_TITLE", @"Title of Canlendar");
	_calPicker.delegate = self;
	dataSource = [[WACalendarPickerDataSource alloc] init];
	_calPicker.dataSource = dataSource;
	
	UIButton *todayButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[todayButton setFrame:CGRectMake(0, 0, 57, 26)];
	[todayButton setBackgroundImage:[UIImage imageNamed:@"CalBtn"] forState:UIControlStateNormal];
	[todayButton setBackgroundImage:[UIImage imageNamed:@"CalBtnPress"] forState:UIControlStateHighlighted];
	[todayButton setTitle:NSLocalizedString(@"CALENDAR_TODAY_BUTTON", "Today button in calendar picker") forState:UIControlStateNormal];
	todayButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
	[todayButton setTitleColor:[UIColor colorWithRed:0.894f green:0.435f blue:0.353f alpha:1.f] forState:UIControlStateNormal];
  todayButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
  todayButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	[todayButton addTarget:self action:@selector(handleSelectToday) forControlEvents:UIControlEventTouchUpInside];

	UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[cancelButton setFrame:CGRectMake(0, 0, 57, 26)];
	[cancelButton setBackgroundImage:[UIImage imageNamed:@"CalBtn"] forState:UIControlStateNormal];
	[cancelButton setBackgroundImage:[UIImage imageNamed:@"CalBtnPress"] forState:UIControlStateHighlighted];
	[cancelButton setTitle:NSLocalizedString(@"CALENDAR_CANCEL_BUTTON", "Cancel button in calendar picker") forState:UIControlStateNormal];
	cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
	[cancelButton setTitleColor:[UIColor colorWithRed:0.757f green:0.757f blue:0.757f alpha:1.f] forState:UIControlStateNormal];
	[cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
  cancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
  cancelButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	[cancelButton addTarget:self action:@selector(handleCancel:) forControlEvents:UIControlEventTouchUpInside];
	
	
	UIBarButtonItem *todayBarButton = [[UIBarButtonItem alloc] initWithCustomView:todayButton];
	UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];

	calNavController = [[UINavigationController alloc] initWithRootViewController:_calPicker];
	
	if ([containedClass isSubclassOfClass:[WACalendarPickerViewController class]]) {
		_calPicker.navigationController.navigationBarHidden = YES;
		calNavController.view.frame = CGRectMake(0, 0, 320, 640);
				
		self.navigationItem.leftBarButtonItem = WABarButtonItem([UIImage imageNamed:@"menu"], @"", ^{
			[self.viewDeckController toggleLeftView];
		});

		[self.navigationItem setRightBarButtonItem:todayBarButton animated:YES];
		
		[self.navigationItem setTitle:NSLocalizedString(@"CALENDAR_TITLE", @"Title of Canlendar")];
		
	}
	else {
		calNavController.view.frame = CGRectMake(0, 20, 320, 640);
		calNavController.view.layer.cornerRadius = 3.f;
		calNavController.view.clipsToBounds = YES;

		[_calPicker.navigationItem setLeftBarButtonItem:todayBarButton animated:YES];
		[_calPicker.navigationItem setRightBarButtonItem:cancelBarButton animated:YES];
	}
	

  [self addChildViewController:calNavController];
  [self.view addSubview:calNavController.view];

  [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView commitAnimations];
	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setDataSource:(id)aDataSource
{
  if (_dataSource != aDataSource) {
    _dataSource = aDataSource;
    tableView.dataSource = _dataSource;
  }
}

#pragma mark - UITableViewDelegate protocol conformance

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 54;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	selectedEvent = [[dataSource items] objectAtIndex:indexPath.row];
		
	if ([selectedEvent isKindOfClass:[WAArticle class]]) {

		WAEventViewController *eventVC = [WAEventViewController controllerForArticle:selectedEvent];

		if ([containedClass isSubclassOfClass:[WACalendarPickerViewController class]]) {
			[self.navigationController pushViewController:eventVC animated:YES];
		}
		else {
			[calNavController pushViewController:eventVC animated:YES];
		}
		
	}
	else if ([selectedEvent isKindOfClass:[WAFile class]]) {

		
	}
}

@end
