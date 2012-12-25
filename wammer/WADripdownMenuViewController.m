//
//  WADripdownMenuViewController.m
//  wammer
//
//  Created by Shen Steven on 10/9/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADripdownMenuViewController.h"

@interface WADripdownMenuViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, readwrite, strong) WADripdownMenuCompletionBlock completionBlock;
@property (nonatomic, readwrite, strong) UITableView *tableView;

@property (nonatomic, readwrite, strong) UIView *translucentOverlay;
@property (nonatomic, readwrite, strong) UIButton *tapper;
@property (nonatomic, strong) UIPopoverController *popover;

@property (nonatomic, readwrite, strong) NSMutableArray *menuItems;

- (IBAction) tapperTapped:(id)sender;

@end

static NSString *kWADDViewCellIdentifier = @"DripdownMenuItem";

@implementation WADripdownMenuViewController {
	WADayViewSupportedStyle currentViewStyle;
}


- (id) initForViewStyle:(WADayViewSupportedStyle)style completion:(WADripdownMenuCompletionBlock)completion {
	
	self = [super initWithNibName:nil bundle:nil];

	if (self) {

		currentViewStyle = style;
		self.completionBlock = completion;

	}
	
	return self;
}

- (void)loadView {
	[super loadView];
		
	if(isPhone()) {
		
		CGRect fullScreenFrame = CGRectMake(0, 0, 320, 640);
		self.translucentOverlay = [[UIView alloc] initWithFrame:fullScreenFrame];
		self.translucentOverlay.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		self.translucentOverlay.backgroundColor = [UIColor colorWithWhite:0.9f alpha:0.3f];
		[self.view addSubview:self.translucentOverlay];
		
		self.tapper = [UIButton buttonWithType:UIButtonTypeCustom];
		self.tapper.frame = fullScreenFrame;
		[self.tapper setBackgroundColor:[UIColor clearColor]];
		[self.translucentOverlay addSubview:self.tapper];
		
		self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 220, 200)];
		self.tableView.delegate = self;
		self.tableView.dataSource = self;
		[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kWADDViewCellIdentifier];

		[self.tapper addSubview:self.tableView];
		
	} else {
		
		self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 220, 200)];
		self.tableView.delegate = self;
		self.tableView.dataSource = self;
		[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kWADDViewCellIdentifier];
		self.view.frame = self.tableView.frame;

		[self.view addSubview:self.tableView];
		
	}
	

}

- (void)prepareMenuItems {
	
	static NSArray *origMenuItems;
	origMenuItems = @[
		@{@"style": [NSNumber numberWithUnsignedInteger:WAEventsViewStyle],
			@"title": NSLocalizedString(@"SLIDING_MENU_TITLE_EVENTS", @"Title for Events in the sliding menu"),
			@"icon": [UIImage imageNamed:@"EventsIcon"],
			@"color": [UIColor colorWithRed:0.957 green:0.376 blue:0.298 alpha:1.0]
		},
	
		@{@"style": [NSNumber numberWithUnsignedInteger:WAPhotosViewStyle],
			@"title": NSLocalizedString(@"SLIDING_MENU_TITLE_PHOTOS", @"Title for Photos in the sliding menu"),
			@"icon": [UIImage imageNamed:@"PhotosIcon"],
			@"color": [UIColor colorWithRed:0.96f green:0.647f blue:0.011f alpha:1.0]
		},
	
		@{@"style": [NSNumber numberWithUnsignedInteger:WADocumentsViewStyle],
			@"title": NSLocalizedString(@"SLIDING_MENU_TITLE_DOCS", @"Title for Documents in the sliding menu"),
			@"icon": [UIImage imageNamed:@"DocumentsIcon"],
			@"color": [UIColor colorWithRed:0.72f green:0.701f blue:0.69f alpha:1.0]
		},
	
		@{@"style": [NSNumber numberWithUnsignedInteger:WAWebpagesViewStyle],
			@"title": NSLocalizedString(@"SLIDING_MENU_TITLE_WEBS", @"Title for Web pages in the sliding menu"),
			@"icon": [UIImage imageNamed:@"Webicon"],
			@"color": [UIColor colorWithRed:0.211f green:0.694f blue:0.749f alpha:1.0f]
		}
	];
	
	self.menuItems = [NSMutableArray array];
	
	for (int i = 0; i < origMenuItems.count; i++) {
		if ([origMenuItems[i][@"style"] isEqual:[NSNumber numberWithUnsignedInteger:currentViewStyle]])
			continue;
		
		[self.menuItems addObject:origMenuItems[i]];
	}
}

- (void) presentDDMenuInViewController:(UIViewController*)viewController {

	if (isPhone()) {
		
		[viewController addChildViewController:self];
		[viewController.view addSubview:self.view];
		[self didMoveToParentViewController:viewController];
		
		CGRect menuToRect = self.tableView.frame;
		CGRect menuFromRect = CGRectOffset(menuToRect, 0, -1 * CGRectGetHeight(menuToRect));
		
		__weak WADripdownMenuViewController *wSelf = self;
		self.tableView.frame = menuFromRect;
		self.translucentOverlay.alpha = 0;
		
		[UIView animateWithDuration:0.3f
													delay:0
												options:UIViewAnimationOptionCurveEaseInOut
										 animations:^{
											 
											 wSelf.tableView.frame = menuToRect;
											 wSelf.translucentOverlay.alpha = 1;
											 
										 }
										 completion:^(BOOL finished) {
											 
											 
											 
										 }];
		
	} else {
		
		CGRect newFrame = self.view.frame;
		newFrame.size = self.tableView.frame.size;
		self.view.frame = newFrame;
		self.contentSizeForViewInPopover = self.view.frame.size;
		
		self.popover = [[UIPopoverController alloc] initWithContentViewController:self];
		[self.popover presentPopoverFromRect:CGRectMake(viewController.navigationController.navigationBar.frame.size.width/2, 0, 1, 1)
														 inView:viewController.view
					 permittedArrowDirections:UIPopoverArrowDirectionUp
													 animated:YES];
		
	}
	

}

- (void)viewDidLoad
{
	[super viewDidLoad];

	[self prepareMenuItems];
	[self.tableView reloadData];
	
	
}

- (void) viewWillDisappear:(BOOL)animated {
	
	[super viewWillDisappear:animated];
	if (self.popover) {
		if ([self.popover isPopoverVisible]) {
			[self.popover dismissPopoverAnimated:animated];
			self.popover = nil;
		}
	}
	
}

- (void) runDismissingAnimationWithCompletion:(void(^)(void))block {
	
	CGRect tableViewFromRect = self.tableView.frame;
	CGRect tableViewToRect = CGRectOffset(tableViewFromRect, 0, -1 * CGRectGetHeight(tableViewFromRect));
	
	__weak WADripdownMenuViewController *wSelf = self;
	self.translucentOverlay.alpha = 1;
	self.tableView.frame = tableViewFromRect;
	
	[UIView animateWithDuration:0.3 animations:^{
		
		wSelf.translucentOverlay.alpha = 0;
		wSelf.tableView.frame = tableViewToRect;
		
	} completion:^(BOOL finished) {
		
		if (block)
			block();
		
	}];
	
}

- (IBAction) tapperTapped:(id)sender {
	
	__weak WADripdownMenuViewController *wSelf = self;
	[self runDismissingAnimationWithCompletion:^ {
		if (wSelf.completionBlock)
			wSelf.completionBlock();
	}];
	
}

#pragma mark - UITableView delegate and datasorurce methods
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {

	return 1;

}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	return self.menuItems.count;

}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kWADDViewCellIdentifier forIndexPath:indexPath];
		
	NSDictionary *item = self.menuItems[indexPath.row];
	cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12.0];
	cell.textLabel.text = item[@"title"];
	cell.imageView.image = item[@"icon"];
	
	return cell;
	
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	__weak WADripdownMenuViewController *wSelf = self;
	[self runDismissingAnimationWithCompletion:^{
		if (wSelf.completionBlock)
			wSelf.completionBlock();
	}];
	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
