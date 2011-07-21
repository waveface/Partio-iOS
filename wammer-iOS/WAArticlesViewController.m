//
//  WAArticlesViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WADataStore.h"
#import "WAArticlesViewController.h"
#import "WACompositionViewController.h"
#import "IRPaginatedView.h"


@interface WAArticlesViewController () <IRPaginatedViewDelegate>

@property (nonatomic, readwrite, retain) IRPaginatedView *paginatedView;
@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, readwrite, retain) UIView *coachmarkView;

@end


@implementation WAArticlesViewController
@synthesize paginatedView;
@synthesize fetchedResultsController;
@synthesize managedObjectContext;
@synthesize coachmarkView;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self)
		return nil;
		
	self.title = @"Articles";
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(handleCompose:)] autorelease];
	
	self.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:((^ {
	
		NSFetchRequest *returnedRequest = [[[NSFetchRequest alloc] init] autorelease];
		returnedRequest.entity = [NSEntityDescription entityForName:@"Article" inManagedObjectContext:self.managedObjectContext];
		returnedRequest.sortDescriptors = [NSArray arrayWithObjects:
			[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES],
		nil];
		
		return returnedRequest;
	
	})()) managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
		
	return self;

}

- (void) dealloc {
	
	[paginatedView release];
	[managedObjectContext release];
	[fetchedResultsController release];
	[super dealloc];

}

- (void) loadView {

	self.view = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.view.backgroundColor = [UIColor whiteColor];
	
	self.paginatedView = [[[IRPaginatedView alloc] initWithFrame:(CGRect){ 0, 0, CGRectGetWidth(self.view.frame), 44 }] autorelease];
	self.paginatedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.paginatedView.backgroundColor = [UIColor whiteColor];
	self.paginatedView.delegate = self;
	
	self.coachmarkView = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
	self.coachmarkView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.coachmarkView.opaque = NO;
	self.coachmarkView.backgroundColor = [UIColor clearColor];
	[self.coachmarkView addSubview:((^ {
	
		UILabel *returnedLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		returnedLabel.text = @"No Articles";
		returnedLabel.font = [UIFont boldSystemFontOfSize:18.0f];
		returnedLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
		
		[returnedLabel sizeToFit];
		[returnedLabel setCenter:self.coachmarkView.center];
		
		return returnedLabel;
		
	})())];
	
	
	UIView *paginationSliderContainer = [[[UIView alloc] initWithFrame:(CGRect){ 0, CGRectGetHeight(self.view.frame) - 44, CGRectGetWidth(self.view.frame), 44 }] autorelease];
	paginationSliderContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;	
	
	UISlider *pageSlider = [[[UISlider alloc] initWithFrame:paginationSliderContainer.bounds] autorelease];
	pageSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	
	UIGraphicsBeginImageContextWithOptions((CGSize){ 1, 1 }, NO, 0.0f);
	UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	UIGraphicsBeginImageContextWithOptions((CGSize){ 24, 24 }, NO, 0.0f);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, [[UIColor blackColor] colorWithAlphaComponent:0.35f].CGColor);
	CGContextFillEllipseInRect(context, (CGRect){ 6, 6, 12, 12 });
	UIImage *dotImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	UIImageView *dotImageView = [[[UIImageView alloc] initWithImage:dotImage] autorelease];
	[dotImageView sizeToFit];
	
	[paginationSliderContainer addSubview:dotImageView];
	[paginationSliderContainer addSubview:pageSlider];
	
	[pageSlider setMinimumTrackImage:transparentImage forState:UIControlStateNormal];
	[pageSlider setMaximumTrackImage:transparentImage forState:UIControlStateNormal];
	
	[self.view addSubview:self.paginatedView];
	[self.view addSubview:self.coachmarkView];
	[self.view addSubview:paginationSliderContainer];
	
}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	
	//	I am not really sure this works!
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		[self.fetchedResultsController performFetch:nil];
		[self.paginatedView reloadViews];
		
		BOOL hasContent = [[self.fetchedResultsController fetchedObjects] count];
		self.coachmarkView.hidden = hasContent;
		
	});

}

- (NSUInteger) numberOfViewsInPaginatedView:(IRPaginatedView *)paginatedView {

	return [[self.fetchedResultsController fetchedObjects] count];

}

- (UIView *) viewForPaginatedView:(IRPaginatedView *)aPaginatedView atIndex:(NSUInteger)index {

	UIView *returnedView = [[[UIView alloc] initWithFrame:aPaginatedView.bounds] autorelease];
	returnedView.backgroundColor = [UIColor whiteColor];
	
	UILabel *descriptionLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	descriptionLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
	descriptionLabel.textAlignment = UITextAlignmentCenter;
	descriptionLabel.font = [UIFont boldSystemFontOfSize:18.0f];
	descriptionLabel.text = [NSString stringWithFormat:@"<%@ %x> page for article at index %i", NSStringFromClass([self class]), self, index];
	[descriptionLabel sizeToFit];
	
	descriptionLabel.center = returnedView.center;
	
	[returnedView addSubview:descriptionLabel];
	
	return returnedView;

}

- (UIViewController *) viewControllerForSubviewAtIndex:(NSUInteger)index inPaginatedView:(IRPaginatedView *)paginatedView {

	return nil;

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
