//
//  WASwipeableTableViewController.m
//  wammer
//
//  Created by Shen Steven on 10/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WASwipeableTableViewController.h"
#import "WADefines.h"
#import "WATimelineViewControllerPhone.h"
#import "WADataStore.h"
#import "WADataStore+FetchingConveniences.h"
#import "IRTableView.h"
#import "WAPulldownRefreshView.h"

#import "WARemoteInterface.h"

@interface WASwipeableTableViewController ()

@property (nonatomic, readwrite, strong) NSMutableArray *tableViews;
@property (nonatomic, readwrite, assign) NSUInteger indexOfCurrentTableView;

@end

@implementation WASwipeableTableViewController
@synthesize tableView, tableViews, indexOfCurrentTableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self)
			return nil;
	

	
	return self;
}

- (WAPulldownRefreshView *) defaultPulldownRefreshView {
	
	return [WAPulldownRefreshView viewFromNib];
	
}


- (void)viewDidLoad
{
	[super viewDidLoad];

	CGRect origFrame = self.view.frame;
	CGRect tbFrame = {CGPointZero, origFrame.size};
	UIView *newView = [[UIView alloc] initWithFrame:tbFrame];

	self.tableViews = [[NSMutableArray alloc] initWithCapacity:3];
	__weak id wSelf = self;
	
	IRTableView* (^setupTableView)(void) = ^(void) {
		
		IRTableView *tbView = [[IRTableView alloc] initWithFrame:tbFrame];

		tbView.separatorStyle = UITableViewCellSeparatorStyleNone;

		WAPulldownRefreshView *pulldownHeader = [self defaultPulldownRefreshView];
		
		tbView.pullDownHeaderView = pulldownHeader;
		tbView.onPullDownMove = ^ (CGFloat progress) {
			[pulldownHeader setProgress:progress animated:YES];
		};
		tbView.onPullDownEnd = ^ (BOOL didFinish) {
			if (didFinish) {
				pulldownHeader.progress = 0;
				[pulldownHeader setBusy:YES animated:YES];
				[[WARemoteInterface sharedInterface] performAutomaticRemoteUpdatesNow];
			}
		};
		tbView.onPullDownReset = ^ {
			[pulldownHeader setBusy:NO animated:YES];
		};
		
		tbView.separatorColor = [UIColor colorWithRed:232.0/255.0 green:232/255.0 blue:226/255.0 alpha:1.0];
		tbView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

		tbView.layer.masksToBounds = NO;
		tbView.layer.shadowRadius = 10;
		tbView.layer.shadowOpacity = 0.5;
		tbView.layer.shadowColor = [[UIColor blackColor] CGColor];
		tbView.layer.shadowOffset = CGSizeZero;
		tbView.layer.shadowPath = [[UIBezierPath bezierPathWithRect:tbView.bounds] CGPath];

		tbView.delegate = wSelf;
		tbView.dataSource = wSelf;
		return tbView;
		
	};
	
	for (int i = 0; i < 3; i ++) {
		[self.tableViews addObject:setupTableView()];
	}

	UISwipeGestureRecognizer *leftSwipeGR = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeft:)];
	leftSwipeGR.direction = UISwipeGestureRecognizerDirectionLeft;
	[newView addGestureRecognizer:leftSwipeGR];
	
	UISwipeGestureRecognizer *rightSwipeGR = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight:)];
	rightSwipeGR.direction = UISwipeGestureRecognizerDirectionRight;
	[newView addGestureRecognizer:rightSwipeGR];
	
	self.indexOfCurrentTableView = 0;
	self.tableView = [self.tableViews objectAtIndex:0];
	[newView addSubview:self.tableView];
	self.view = newView;
	
}


- (void) handleSwipeRight:(UISwipeGestureRecognizer*)swipe {

	[NSException raise:NSInternalInconsistencyException format:@"Subclass shall implement %s", __PRETTY_FUNCTION__];

}

- (void) handleSwipeLeft:(UISwipeGestureRecognizer*)swipe {

	[NSException raise:NSInternalInconsistencyException format:@"Subclass shall implement %s", __PRETTY_FUNCTION__];

}

- (void) pushTableViewToLeftWithDuration:(float)duration completion:(void(^)(void))completionBlock {
  
	IRTableView *currentView = [self.tableViews objectAtIndex:self.indexOfCurrentTableView];
	[currentView resetPullDown];
	
	NSUInteger nextIndex = (self.indexOfCurrentTableView + 1) % 3;
	IRTableView *nextTbView = [self.tableViews objectAtIndex:nextIndex];
	
	CGRect origFrame = currentView.frame;
  CGRect offScreenFrame = origFrame;
  offScreenFrame.origin.x = -(origFrame.size.width) - self.tableView.layer.shadowRadius;
	
	[self.view addSubview:nextTbView];
	[self.view sendSubviewToBack:nextTbView];

	__weak WASwipeableTableViewController *wSelf = self;

  [UIView animateWithDuration:duration
												delay:0
											options: UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     
										 currentView.frame = offScreenFrame;
                     
                   } completion:^(BOOL finished) {

										 [currentView removeFromSuperview];
										 [wSelf.view bringSubviewToFront:[wSelf.tableViews objectAtIndex:nextIndex]];
										 currentView.frame = origFrame;
										 wSelf.indexOfCurrentTableView = nextIndex;
										 wSelf.tableView = [wSelf.tableViews objectAtIndex:wSelf.indexOfCurrentTableView];
                     
                     if (completionBlock)
                       completionBlock();
                     
                   }];
  
}

- (void) pullTableViewFromRightWithDuration:(float)duration completion:(void(^)(void))completionBlock {
  
	IRTableView *currentView = [self.tableViews objectAtIndex:self.indexOfCurrentTableView];
	[currentView resetPullDown];
	
	NSUInteger preIndex = 2;
	if (self.indexOfCurrentTableView > 0)
		preIndex = self.indexOfCurrentTableView - 1;
	
	IRTableView *preView = [self.tableViews objectAtIndex:preIndex];
	
	CGRect origFrame = currentView.frame;
  CGRect offScreenFrame = origFrame;
  offScreenFrame.origin.x = -(origFrame.size.width) - self.tableView.layer.shadowRadius;
 
	preView.frame = offScreenFrame;
	[self.view addSubview:preView];
	[self.view bringSubviewToFront:preView];
	
	__weak WASwipeableTableViewController *wSelf = self;
	
  [UIView animateWithDuration:duration
												delay:0
											options: UIViewAnimationOptionCurveEaseInOut 
                   animations:^{
                     
										 preView.frame = origFrame;
                     
                   } completion:^(BOOL finished) {
										 
										 [currentView removeFromSuperview];
//										 [wSelf.view sendSubviewToBack:currentView];
										 wSelf.indexOfCurrentTableView = preIndex;
										 wSelf.tableView = [wSelf.tableViews objectAtIndex:wSelf.indexOfCurrentTableView];
                     
                     if (completionBlock)
                       completionBlock();
                     
                   }];
  
}

- (IRTableView *) tableViewRight {
	
	NSUInteger preIndex = (self.indexOfCurrentTableView + 1) % 3;
	
	return [self.tableViews objectAtIndex:preIndex];
	
}

- (IRTableView *) tableViewLeft {
	
	NSUInteger nextIndex = 2;
	if (self.indexOfCurrentTableView > 0)
		nextIndex = self.indexOfCurrentTableView - 1;
	
	return [self.tableViews objectAtIndex:nextIndex];
	
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
