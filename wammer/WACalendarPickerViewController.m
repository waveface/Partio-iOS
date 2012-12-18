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
#import "WAAppearance.h"
#import "WASlidingMenuViewController.h"
#import "Kal.h"
#import "WAFileAccessLog.h"

#define kScreenWidth ((CGFloat)([UIScreen mainScreen].bounds.size.width))
#define kScreenHeight ((CGFloat)([UIScreen mainScreen].bounds.size.height))

@interface WACalendarPickerViewController ()
{
	KalViewController *calPicker;
	id dataSource;
	UITableView *tableView;
	WAArticle *selectedEvent;
}

@end

@implementation WACalendarPickerViewController

- (WACalendarPickerViewController *)initWithFrame:(CGRect)frame style:(WACalendarPickerStyle)style
{
	calPicker = [[KalViewController alloc] init];
	calPicker.title = NSLocalizedString(@"TITLE_CALENDAR", @"Title of Canlendar");
	calPicker.delegate = self;
	dataSource = [[WACalendarPickerDataSource alloc] init];
	calPicker.dataSource = dataSource;
	calPicker.frame = frame;

	switch (style) {
		case WACalendarPickerStyleInPopover:
			[calPicker.navigationItem setRightBarButtonItem:[self todayBarButton] animated:YES];
			break;
			
		case WACalendarPickerStyleMenuToday:
			[calPicker.navigationItem setLeftBarButtonItem:[self menuBarButton] animated:YES];
			[calPicker.navigationItem setRightBarButtonItem:[self todayBarButton] animated:YES];
			break;
			
		case WACalendarPickerStyleTodayCancel:
			[calPicker.navigationItem setLeftBarButtonItem:[self cancelBarButton] animated:YES];
			[calPicker.navigationItem setRightBarButtonItem:[self todayBarButton] animated:YES];
			break;
			
		default:
			break;
	}
		
	return [self initWithRootViewController:calPicker];
}

- (UIBarButtonItem *)menuBarButton
{
	return (UIBarButtonItem *)WABarButtonItem([UIImage imageNamed:@"menu"], @"", ^{
		[self.viewDeckController toggleLeftView];
	});
}

- (UIBarButtonItem *)todayBarButton
{
	UIButton *todayButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[todayButton setFrame:CGRectMake(0, 0, 57, 26)];
	[todayButton setBackgroundImage:[UIImage imageNamed:@"Kal.bundle/CalBtn"] forState:UIControlStateNormal];
	[todayButton setBackgroundImage:[UIImage imageNamed:@"Kal.bundle/CalBtnPress"] forState:UIControlStateHighlighted];
	[todayButton setTitle:NSLocalizedString(@"CALENDAR_TODAY_BUTTON", "Today button in calendar picker") forState:UIControlStateNormal];
	todayButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
	[todayButton setTitleColor:[UIColor colorWithRed:0.894f green:0.435f blue:0.353f alpha:1.f] forState:UIControlStateNormal];
  todayButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
  todayButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	[todayButton addTarget:self action:@selector(handleSelectToday) forControlEvents:UIControlEventTouchUpInside];

	return [[UIBarButtonItem alloc] initWithCustomView:todayButton];
}

- (UIBarButtonItem *)cancelBarButton
{
	UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[cancelButton setFrame:CGRectMake(0, 0, 57, 26)];
	[cancelButton setBackgroundImage:[UIImage imageNamed:@"Kal.bundle/CalBtn"] forState:UIControlStateNormal];
	[cancelButton setBackgroundImage:[UIImage imageNamed:@"Kal.bundle/CalBtnPress"] forState:UIControlStateHighlighted];
	[cancelButton setTitle:NSLocalizedString(@"CALENDAR_CANCEL_BUTTON", "Cancel button in calendar picker") forState:UIControlStateNormal];
	cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.f];
	[cancelButton setTitleColor:[UIColor colorWithRed:0.757f green:0.757f blue:0.757f alpha:1.f] forState:UIControlStateNormal];
	[cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
  cancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
  cancelButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	[cancelButton addTarget:self action:@selector(handleCancel:) forControlEvents:UIControlEventTouchUpInside];
	
	return [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
}

- (void)handleCancel:(UIButton *)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void) handleSelectToday
{
	[calPicker showAndSelectDate:[NSDate date]];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
  
	self.view.backgroundColor = [UIColor whiteColor];
	self.view.layer.cornerRadius = 3.f;
	self.view.clipsToBounds = YES;
	
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	calPicker.frame = self.view.frame;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
		
		if (isPad()) {
			UINavigationController *navC = [[WANavigationController alloc] initWithRootViewController:eventVC];
			navC.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentViewController:navC animated:YES completion:nil];
			
		} else {
			[self pushViewController:eventVC animated:YES];
			
		}

	}
	else if ([selectedEvent isKindOfClass:[WAFile class]]) {

		WAFile *file = (WAFile *)selectedEvent;
		WASlidingMenuViewController *smVC;
		
		if (file.created) {
			if (self.viewDeckController) {
				
				smVC = (WASlidingMenuViewController *)[self.viewDeckController leftController];
				[smVC switchToViewStyle:WAPhotosViewStyle onDate:file.created animated:YES];
				
			}
			else {
				
				smVC = (WASlidingMenuViewController *)[[[self delegate] viewDeckController] leftController];
				[smVC switchToViewStyle:WAPhotosViewStyle onDate:file.created animated:NO];
				
				if (isPhone()) {
					[self dismissViewControllerAnimated:YES completion:nil];
			
				}
				
			}
		}
		
	} else if ([selectedEvent isKindOfClass:[WAFileAccessLog class]]) {

		WAFileAccessLog *file = (WAFileAccessLog *)selectedEvent;
		WASlidingMenuViewController *smVC;

		if (self.viewDeckController) {
			
			smVC = (WASlidingMenuViewController *)[self.viewDeckController leftController];
			[smVC switchToViewStyle:WADocumentsViewStyle onDate:file.accessTime animated:YES];
			
		}
		else {
			
			smVC = (WASlidingMenuViewController *)[[[self delegate] viewDeckController] leftController];
			[smVC switchToViewStyle:WADocumentsViewStyle onDate:file.accessTime animated:NO];
			
			if (isPhone()) {
				[self dismissViewControllerAnimated:YES completion:nil];
			
			}
			
		}

	}
	
}

#pragma mark - Orientation

- (NSUInteger)supportedInterfaceOrientations
{
	
	if (isPad()) {
		return UIInterfaceOrientationMaskAll;
	} else
		return UIInterfaceOrientationMaskPortrait;
	
}

- (BOOL)shouldAutorotate
{
	
	return YES;
	
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

  CGFloat kFrameWidth = self.view.frame.size.width;
  CGFloat kFrameHeight = self.view.frame.size.height;
	
  if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
    calPicker.view.frame = CGRectMake(0, 0, kFrameWidth, kFrameHeight);
  }
  else if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
    calPicker.view.frame = CGRectMake(0, 0, kFrameHeight, kFrameWidth);
  }

}

@end
