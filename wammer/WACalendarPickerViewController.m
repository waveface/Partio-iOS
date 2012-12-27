//
//  WACalendarPickerByTypeViewController.m
//  wammer
//
//  Created by Greener Chen on 12/11/21.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WACalendarPickerViewController.h"
#import "WACalendarPickerDataSource.h"
#import "WACalendarPickerPanelViewCell.h"
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
	WAArticle *selectedEvent;
	WACalendarPickerStyle calStyle;
}

@end

@implementation WACalendarPickerViewController

- (WACalendarPickerViewController *)initWithFrame:(CGRect)frame style:(WACalendarPickerStyle)style selectedDate:(NSDate *)date
{
	
	calPicker = [[KalViewController alloc] initWithSelectedDate:date];
	calPicker.title = NSLocalizedString(@"TITLE_CALENDAR", @"Title of Canlendar");
	calPicker.delegate = self;
	dataSource = [[WACalendarPickerDataSource alloc] init];
	calPicker.dataSource = dataSource;
	calPicker.frame = frame;
	calStyle = style;
	
	switch (style) {
		case WACalendarPickerStyleInPopover: {
			[calPicker.navigationItem setRightBarButtonItem:[self todayBarButton] animated:YES];
			break;
		}
			
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
		
	return [super initWithRootViewController:calPicker];
}

- (UIBarButtonItem *)dismissBarButton
{
	return (UIBarButtonItem *)WABarButtonItemWithButton([self cancelUIButton], ^{
		[self.delegate dismissPopoverAnimated:YES];
	});
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
	[todayButton setFrame:CGRectMake(0.f, 0.f, 57.f, 26.f)];
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

- (UIButton *)cancelUIButton
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
	
	return cancelButton;
}

- (UIBarButtonItem *)cancelBarButton
{
	UIButton *cancelButton = [self cancelUIButton];
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
		CGSize shadowSize = CGSizeMake(15.0, 1.0);
		UIGraphicsBeginImageContext(shadowSize);
		CGContextRef shadowContext = UIGraphicsGetCurrentContext();
		CGContextSetFillColorWithColor(shadowContext, [UIColor colorWithRed:193/255.0 green:193/255.0 blue:193/255.0 alpha:1].CGColor);
		CGContextAddRect(shadowContext, CGRectMake(7.0, 0, 1.0, shadowSize.height));
		CGContextFillPath(shadowContext);
		UIImage *naviShadow = UIGraphicsGetImageFromCurrentImageContext();
		UIImage *naviShadowWithInsets = [naviShadow resizableImageWithCapInsets:UIEdgeInsetsMake(0, 7, 0, 7)];
		UIGraphicsEndImageContext();
		[[UINavigationBar appearance] setShadowImage:naviShadowWithInsets];
		
		WAEventViewController *eventVC = [WAEventViewController controllerForArticle:selectedEvent];
		
		if (isPad()) {
			UINavigationController *navC = [[WANavigationController alloc] initWithRootViewController:eventVC];
			navC.modalPresentationStyle = UIModalPresentationFormSheet;
			[self presentViewController:navC animated:YES completion:nil];
			
		} else {
			[self pushViewController:eventVC animated:YES];
			
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

#pragma mark - icon buttons

- (IBAction)handleEvents:(UIButton *)sender
{
	WASlidingMenuViewController *smVC;
	
	if (self.viewDeckController) {
		
		smVC = (WASlidingMenuViewController *)[self.viewDeckController leftController];
		[smVC switchToViewStyle:WAEventsViewStyle onDate:[calPicker selectedNSDate] animated:YES];
		
	}
}

- (IBAction)handlePhotos:(UIButton *)sender
{
	WASlidingMenuViewController *smVC;
	
	if (self.viewDeckController) {
		
		smVC = (WASlidingMenuViewController *)[self.viewDeckController leftController];
		[smVC switchToViewStyle:WAPhotosViewStyle onDate:[calPicker selectedNSDate] animated:YES];
		
	}
	
}

- (IBAction)handleDocs:(UIButton *)sender
{
	WASlidingMenuViewController *smVC;
	
	if (self.viewDeckController) {
		
		smVC = (WASlidingMenuViewController *)[self.viewDeckController leftController];
		[smVC switchToViewStyle:WADocumentsViewStyle onDate:[calPicker selectedNSDate] animated:YES];
		
	}

}

- (IBAction)handleWebpages:(UIButton *)sender
{
	WASlidingMenuViewController *smVC;
	
	if (self.viewDeckController) {
		
		smVC = (WASlidingMenuViewController *)[self.viewDeckController leftController];
		[smVC switchToViewStyle:WAWebpagesViewStyle onDate:[calPicker selectedNSDate] animated:YES];
		
	}

}

@end
