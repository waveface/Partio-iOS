//
//  WAAttachedMediaListViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/26/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAAttachedMediaListViewController.h"
#import "WAView.h"


@interface WAAttachedMediaListViewController ()

@property (nonatomic, readwrite, copy) void(^callback)(NSURL *objectURI);
@property (nonatomic, readwrite, retain) UITableView *tableView;

@end


@implementation WAAttachedMediaListViewController
@synthesize callback, headerView, tableView;

+ (WAAttachedMediaListViewController *) controllerWithArticleURI:(NSURL *)anArticleURI completion:(void(^)(NSURL *objectURI))aBlock {

	return [[[self alloc] initWithArticleURI:anArticleURI completion:aBlock] autorelease];

}

- (id) init {

	return [self initWithArticleURI:nil completion:nil];

}

- (WAAttachedMediaListViewController *) initWithArticleURI:(NSURL *)anArticleURI completion:(void (^)(NSURL *))aBlock {

	self = [super init];
	if (!self)
		return nil;
	
	__block __typeof__(self) nrSelf = self;
		
	self.navigationItem.rightBarButtonItem = [IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemDone wiredAction:^(IRBarButtonItem *senderItem) {
		
		if (nrSelf.callback)
			nrSelf.callback(nil);
		
	}];
	
	self.callback = aBlock;
	self.title = @"Attachments";
	
	return self;

}

- (void) dealloc {

	[callback release];
	[headerView release];
	[super dealloc];

}





- (void) loadView {

	self.view = [[[WAView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.rootViewController.view.bounds] autorelease]; // dummy size for autoresizing
	
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPhotoQueueBackground"]];
	
	self.tableView = [[[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain] autorelease];
	[self.view addSubview:self.tableView];
	
	self.tableView.layer.borderColor = [UIColor redColor].CGColor;
	self.tableView.layer.borderWidth = 2.0f;
	
	__block __typeof__(self) nrSelf = self;
	
	((WAView *)self.view).onLayoutSubviews = ^ {
	
		//	Handle header view conf
		
		CGFloat headerViewHeight = 0.0f;
		
		if (nrSelf.headerView) {
			[nrSelf.view addSubview:nrSelf.headerView];
			headerViewHeight = CGRectGetHeight(nrSelf.headerView.bounds);
		}
			
		nrSelf.headerView.frame = (CGRect){
			CGPointZero,
			(CGSize){
				CGRectGetWidth(nrSelf.view.bounds),
				CGRectGetHeight(nrSelf.headerView.bounds)
			}
		};
		
		nrSelf.tableView.frame = (CGRect){
			(CGPoint){
				0,
				headerViewHeight
			},
			(CGSize){
				CGRectGetWidth(nrSelf.view.bounds),
				CGRectGetHeight(nrSelf.view.bounds) - headerViewHeight
			}
		};
		
		//	Relocate table view
	
	};

}

- (void) viewDidUnload {

	self.headerView = nil;
	
	[super viewDidUnload];

}





- (void) setHeaderView:(UIView *)newHeaderView {

	if (headerView == newHeaderView)
		return;
	
	if ([headerView isDescendantOfView:self.view])
		[headerView removeFromSuperview];
	
	[self willChangeValueForKey:@"headerView"];
	[headerView release];
	headerView = [newHeaderView retain];
	[self didChangeValueForKey:@"headerView"];
	
	[self.view setNeedsLayout];

} 

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

@end
