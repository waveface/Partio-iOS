//
//  WAArticlesViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAArticlesViewController.h"
#import "WACompositionViewController.h"


@interface WAArticlesViewController () <IRPaginatedViewDelegate>

@end


@implementation WAArticlesViewController
@dynamic view;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self)
		return nil;
		
	self.title = @"Articles";
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(handleCompose:)] autorelease];
	
	return self;

}

- (void) loadView {

	self.view = [[[IRPaginatedView alloc] initWithFrame:CGRectZero] autorelease];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.view.backgroundColor = [UIColor whiteColor];
	
	self.view.delegate = self;
	
}

- (NSUInteger) numberOfViewsInPaginatedView:(IRPaginatedView *)paginatedView {

	return 200;

}

- (UIView *) viewForPaginatedView:(IRPaginatedView *)paginatedView atIndex:(NSUInteger)index {

	UIView *returnedView = [[[UIView alloc] initWithFrame:paginatedView.bounds] autorelease];
	returnedView.backgroundColor = [UIColor whiteColor];
	
	UILabel *descriptionLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
	descriptionLabel.textAlignment = UITextAlignmentCenter;
	descriptionLabel.font = [UIFont boldSystemFontOfSize:18.0f];
	descriptionLabel.text = NSStringFromClass([self class]);
	[descriptionLabel sizeToFit];
	
	descriptionLabel.center = returnedView.center;
	
	[returnedView addSubview:descriptionLabel];
	
	return returnedView;

}

- (UIViewController *) viewControllerForSubviewAtIndex:(NSUInteger)index inPaginatedView:(IRPaginatedView *)paginatedView {

	return nil;

}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	
	[self.view reloadViews];

}

- (void) handleCompose:(UIBarButtonItem *)sender {

	WACompositionViewController *compositionVC = [[[WACompositionViewController alloc] init] autorelease];
	
	UINavigationController *wrapperNC = [[[UINavigationController alloc] initWithRootViewController:compositionVC] autorelease];
	wrapperNC.modalPresentationStyle = UIModalPresentationFormSheet;
	
	[(self.navigationController ? self.navigationController : self) presentModalViewController:wrapperNC animated:YES];

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

	return YES;
	
}

@end
