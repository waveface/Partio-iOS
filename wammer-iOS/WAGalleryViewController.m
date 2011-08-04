//
//  WAGalleryViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/3/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAGalleryViewController.h"
#import "IRPaginatedView.h"
#import "WADataStore.h"
#import "WAGalleryImageView.h"


@interface WAGalleryViewController () <IRPaginatedViewDelegate, UIGestureRecognizerDelegate, UINavigationBarDelegate>

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) WAArticle *article;
@property (nonatomic, readwrite, retain) IRPaginatedView *paginatedView;

@property (nonatomic, readwrite, retain) UINavigationBar *navigationBar;
@property (nonatomic, readwrite, retain) UIToolbar *toolbar;
@property (nonatomic, readwrite, retain) UINavigationItem *previousNavigationItem;

- (void) waSubviewWillLayout;

@property (nonatomic ,readwrite, assign) BOOL contextControlsShown;
- (void) setContextControlsHidden:(BOOL)willHide animated:(BOOL)animate completion:(void(^)(void))callback;
- (void) setContextControlsHidden:(BOOL)willHide animated:(BOOL)animate barringInteraction:(BOOL)barringInteraction completion:(void(^)(void))callback;

@end


@implementation WAGalleryViewController
@dynamic view;
@synthesize managedObjectContext, fetchedResultsController, article;
@synthesize navigationBar, toolbar, previousNavigationItem;
@synthesize paginatedView;
@synthesize contextControlsShown;


+ (WAGalleryViewController *) controllerRepresentingArticleAtURI:(NSURL *)anArticleURI {

	WAGalleryViewController *returnedController = [[[self alloc] init] autorelease];
	
	returnedController.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	returnedController.article = (WAArticle *)[returnedController.managedObjectContext irManagedObjectForURI:anArticleURI];
	
	return returnedController;

}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	self.wantsFullScreenLayout = YES;
	
	return self;

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {

	return YES;

}

- (NSFetchedResultsController *) fetchedResultsController {

	if (fetchedResultsController)
		return fetchedResultsController;
		
	NSFetchRequest *fetchRequest = [self.managedObjectContext.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRFilesForArticle" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
		self.article, @"Article",
	nil]];
	
	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
		[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES],
	nil];
		
	self.fetchedResultsController = [[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil] autorelease];
	
	NSError *fetchingError;
	if (![self.fetchedResultsController performFetch:&fetchingError])
		NSLog(@"Error fetching: %@", fetchingError);
		
	self.previousNavigationItem.title = self.article.text;
	
	return fetchedResultsController;

}

- (void) loadView {

	__block __typeof__(self) nrSelf = self;

	self.view = [[[WAView alloc] initWithFrame:CGRectZero] autorelease];
	self.view.backgroundColor = [UIColor blackColor];
	self.view.onLayoutSubviews = ^ {
		[nrSelf waSubviewWillLayout];
	};
	
	self.previousNavigationItem = [[[UINavigationItem alloc] initWithTitle:@"PREVIOUS ARTICLE"] autorelease];
	
	self.paginatedView = [[[IRPaginatedView alloc] initWithFrame:self.view.bounds] autorelease];
	self.paginatedView.horizontalSpacing = 24.0f;
	self.paginatedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.paginatedView.delegate = self;
	
	self.navigationBar = [[[UINavigationBar alloc] initWithFrame:(CGRect){ 0.0f, 0.0f, CGRectGetWidth(self.view.bounds), 44.0f }] autorelease];
	self.navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
	self.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	self.navigationBar.delegate = self;
	[self.navigationBar pushNavigationItem:self.previousNavigationItem animated:NO];
	[self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
	
	self.toolbar = [[[UIToolbar alloc] initWithFrame:(CGRect){ 0.0f, CGRectGetHeight(self.view.bounds) - 44.0f, CGRectGetWidth(self.view.bounds), 44.0f }] autorelease];
	self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
	self.toolbar.barStyle = UIBarStyleBlackTranslucent;
	
	[self.view addSubview:self.paginatedView];
	[self.view addSubview:self.navigationBar];
	[self.view addSubview:self.toolbar];
	
	self.contextControlsShown = YES;
	[self setContextControlsHidden:YES animated:NO completion:nil];
	
	UITapGestureRecognizer *tapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBackgroundTap:)] autorelease];
	tapRecognizer.delegate = self;
	[self.view addGestureRecognizer:tapRecognizer];

}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	[self.paginatedView reloadViews];

}

- (void) waSubviewWillLayout {

	self.navigationBar.frame = (CGRect){
	
		(CGPoint){
			self.navigationBar.frame.origin.x,
			MAX(20, [self.view convertRect:[[UIApplication sharedApplication] statusBarFrame] fromView:nil].size.height)
		},
		self.navigationBar.frame.size
	
	};

}





- (BOOL) navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {

	dispatch_async(dispatch_get_main_queue(), ^ {

		[self dismissModalViewControllerAnimated:YES];
	
	});
	
	return NO;

}

- (NSUInteger) numberOfViewsInPaginatedView:(IRPaginatedView *)paginatedView {

	return [self.article.files count];

}

- (UIView *) viewForPaginatedView:(IRPaginatedView *)aPaginatedView atIndex:(NSUInteger)index {

	//	HEH

	WAFile *representedFile = (WAFile *)[self.fetchedResultsController.fetchedObjects objectAtIndex:index];
	NSString *resourceName = [NSString stringWithFormat:@"IPSample_%03i", (1 + (rand() % 48))];
	NSString *resourceFilePath = [[[NSBundle mainBundle] URLForResource:resourceName withExtension:@"jpg" subdirectory:@"IPSample"] path];
	
	WAGalleryImageView *returnedView =  [WAGalleryImageView viewForImage:[UIImage imageWithContentsOfFile:resourceFilePath]];
	
	return returnedView;

}

- (UIViewController *) viewControllerForSubviewAtIndex:(NSUInteger)index inPaginatedView:(IRPaginatedView *)paginatedView {

	return nil;

}





- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {

	if (![gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]])
		return YES;

	if (!self.contextControlsShown)
		return YES;
		
	if (CGRectContainsPoint(UIEdgeInsetsInsetRect(self.navigationBar.bounds, (UIEdgeInsets){ -20, -20, -20, -20 }), [touch locationInView:self.navigationBar]))
		return NO;
	
	if (CGRectContainsPoint(UIEdgeInsetsInsetRect(self.toolbar.bounds, (UIEdgeInsets){ -20, -20, -20, -20 }), [touch locationInView:self.toolbar]))
		return NO;
	
	return YES;

}

- (void) handleBackgroundTap:(UITapGestureRecognizer *)tapRecognizer {

	[self setContextControlsHidden:self.contextControlsShown animated:YES completion:nil];

}

- (void) setContextControlsHidden:(BOOL)willHide animated:(BOOL)animate completion:(void(^)(void))callback {

	[self setContextControlsHidden:willHide animated:animate barringInteraction:YES completion:callback];

}

- (void) setContextControlsHidden:(BOOL)willHide animated:(BOOL)animate barringInteraction:(BOOL)barringInteraction completion:(void(^)(void))callback {

	if (contextControlsShown == !willHide)
		return;
	
	NSTimeInterval animationDuration = animate ? 0.3f : 0.0f;
	
	if (barringInteraction) {
	
		[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, animationDuration * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		});	
	
	}
	
	[[UIApplication sharedApplication] setStatusBarHidden:willHide withAnimation:(animate ? UIStatusBarAnimationFade : UIStatusBarAnimationNone)];
	[self.view setNeedsLayout];
	[self.view layoutSubviews];
	
	[UIView animateWithDuration:animationDuration delay:0.0f options:(barringInteraction ? 0 : UIViewAnimationOptionAllowUserInteraction) animations:^(void) {
	
		self.navigationBar.alpha = (willHide ? 0.0f : 1.0f);
		self.toolbar.alpha = (willHide ? 0.0f : 1.0f);
		
	} completion: ^ (BOOL didFinish){
	
		if (callback)
			callback();
			
	}];
	
	self.contextControlsShown = willHide ? NO : YES;

}





- (void) viewDidUnload {

	self.paginatedView = nil;
	self.navigationBar = nil;
	self.toolbar = nil;
	
	[super viewDidUnload];

}

- (void) dealloc {

	[managedObjectContext release];
	[article release];
	[previousNavigationItem release];
	
	[navigationBar release];
	[toolbar release];
	[paginatedView release];
	
	[super dealloc];

}

@end
