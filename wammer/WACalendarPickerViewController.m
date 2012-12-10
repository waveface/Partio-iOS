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

#define kCalWidth 320.f
#define kCalHeight ((CGFloat)([UIScreen mainScreen].bounds.size.height))

@interface WACalendarPickerViewController ()
{
	KalViewController *calPicker;
	id dataSource;
	UITableView *tableView;
	WAArticle *selectedEvent;
}

@end

@implementation WACalendarPickerViewController

- (id)initWithLeftButton:(WABarButtonCalItem)leftBarButton
						 RightButton:(WABarButtonCalItem)rightBarButton
{
	calPicker = [[KalViewController alloc] init];
	calPicker.title = NSLocalizedString(@"CALENDAR_TITLE", @"Title of Canlendar");
	calPicker.delegate = self;
	dataSource = [[WACalendarPickerDataSource alloc] init];
	calPicker.dataSource = dataSource;

	switch (leftBarButton) {
		case WABarButtonCalItemMenu:
			[calPicker.navigationItem setLeftBarButtonItem:[self menuBarButton] animated:YES];
			break;
			
		case WABarButtonCalItemToday:
			[calPicker.navigationItem setLeftBarButtonItem:[self todayBarButton] animated:YES];
			break;
			
		case WABarButtonCalItemCancel:
			[calPicker.navigationItem setLeftBarButtonItem:[self cancelBarButton] animated:YES];
			break;
			
		default:
			break;
	}
		
	switch (rightBarButton) {
		case WABarButtonCalItemMenu:
			[calPicker.navigationItem setRightBarButtonItem:[self menuBarButton] animated:YES];
			break;
			
		case WABarButtonCalItemToday:
			[calPicker.navigationItem setRightBarButtonItem:[self todayBarButton] animated:YES];
			break;
			
		case WABarButtonCalItemCancel:
			[calPicker.navigationItem setRightBarButtonItem:[self cancelBarButton] animated:YES];
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
	[todayButton setBackgroundImage:[UIImage imageNamed:@"CalBtn"] forState:UIControlStateNormal];
	[todayButton setBackgroundImage:[UIImage imageNamed:@"CalBtnPress"] forState:UIControlStateHighlighted];
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
	[cancelButton setBackgroundImage:[UIImage imageNamed:@"CalBtn"] forState:UIControlStateNormal];
	[cancelButton setBackgroundImage:[UIImage imageNamed:@"CalBtnPress"] forState:UIControlStateHighlighted];
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
  
	if (isPad()) {
		self.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	
	self.view.backgroundColor = [UIColor blackColor];
	self.view.layer.cornerRadius = 3.f;
	self.view.clipsToBounds = YES;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setDataSource:(id)aDataSource
{
  if (dataSource != aDataSource) {
    dataSource = aDataSource;
    tableView.dataSource = dataSource;
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
		[self pushViewController:eventVC animated:YES];
		
	}
	else if ([selectedEvent isKindOfClass:[WAFile class]]) {

		WAFile *photo = (WAFile *)selectedEvent;
		WASlidingMenuViewController *smVC;
		
		if (self.viewDeckController) {
			
			smVC = (WASlidingMenuViewController *)[self.viewDeckController leftController];
			[smVC switchToViewStyle:WAPhotosViewStyle onDate:photo.created animated:YES];
		
		}
		else {
			
			smVC = (WASlidingMenuViewController *)[[[self delegate] viewDeckController] leftController];
			[smVC switchToViewStyle:WAPhotosViewStyle onDate:photo.created animated:NO];
			[self dismissViewControllerAnimated:YES completion:nil];
		
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

	const CGFloat kScreenWidth = ((CGFloat)([UIScreen mainScreen].bounds.size.width));
	const CGFloat kScreenHeight = ((CGFloat)([UIScreen mainScreen].bounds.size.height));
	
	if (toInterfaceOrientation == UIInterfaceOrientationMaskPortrait) {
		calPicker.view.frame = CGRectMake(0, 0, kCalWidth, kCalHeight);
	}
	else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
		calPicker.view.frame = CGRectMake(kScreenWidth - kCalHeight, 0, kCalHeight, kCalWidth);
	}
	else if (toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
		calPicker.view.frame = CGRectMake(0, 0, kCalWidth, kCalHeight);
	}
	else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
		calPicker.view.frame = CGRectMake(0, kScreenHeight - kCalWidth, kCalHeight, kCalWidth);
	}
}

@end
