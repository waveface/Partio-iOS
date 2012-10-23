//
//  WADripdownMenuViewController.m
//  wammer
//
//  Created by Shen Steven on 10/9/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WADripdownMenuViewController.h"

@interface WADripdownMenuViewController ()

@property (nonatomic, readwrite, strong) WADripdownMenuCompletionBlock completionBlock;
@property (nonatomic, readwrite, weak) IBOutlet UITableView *tableView;
@property (nonatomic, readwrite, weak) IBOutlet UIView *translucentOverlay;
@property (nonatomic, readwrite, weak) IBOutlet UIButton *tapper;

@end

@implementation WADripdownMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id) initWithCompletion:(WADripdownMenuCompletionBlock)completion {
	
	self = [self initWithNibName:nil bundle:nil];

	if (self) {

		self.completionBlock = completion;

	}
	
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
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

	return 3;

}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"DripdownMenuItem";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (!cell) {

		cell = [[UITableViewCell alloc] init];

	}
	
	switch (indexPath.row) {
		case 0:
			cell.textLabel.text = NSLocalizedString(@"TITLE_PHOTO_STREAM", @"Title for menu item Photo Stream");
			break;

		case 1:
			cell.textLabel.text = NSLocalizedString(@"TITLE_READING_STREAM", @"Title for menu item Reading Stream");
			break;
			
		case 2:
			cell.textLabel.text = NSLocalizedString(@"TITLE_DOCUMENT_STREAM", @"Title for menu item Document Stream");
			break;
			
		default:
			break;
	}
	
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
