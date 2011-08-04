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


@interface WAGalleryViewController () <IRPaginatedViewDelegate>
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) WAArticle *article;
@property (nonatomic, readwrite, retain) IRPaginatedView *paginatedView;
@end


@implementation WAGalleryViewController
@synthesize managedObjectContext, fetchedResultsController, article;
@synthesize paginatedView;

+ (WAGalleryViewController *) controllerRepresentingArticleAtURI:(NSURL *)anArticleURI {

	WAGalleryViewController *returnedController = [[[self alloc] init] autorelease];
	
	returnedController.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	returnedController.article = (WAArticle *)[returnedController.managedObjectContext irManagedObjectForURI:anArticleURI];
	
	return returnedController;

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
	
	return fetchedResultsController;

}

- (void) loadView {

	self.view = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
	self.view.backgroundColor = [UIColor blackColor];
	
	self.paginatedView = [[[IRPaginatedView alloc] initWithFrame:self.view.bounds] autorelease];
	self.paginatedView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.paginatedView.delegate = self;
	
	[self.view addSubview:self.paginatedView];

}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	[self.paginatedView reloadViews];

}





- (NSUInteger) numberOfViewsInPaginatedView:(IRPaginatedView *)paginatedView {

	return [self.article.files count];

}

- (UIView *) viewForPaginatedView:(IRPaginatedView *)aPaginatedView atIndex:(NSUInteger)index {

	WAFile *representedFile = (WAFile *)[self.fetchedResultsController.fetchedObjects objectAtIndex:index];
	
	NSString *resourceName = [NSString stringWithFormat:@"IPSample_%03i", (1 + (rand() % 48))];
	NSString *resourceFilePath = [[[NSBundle mainBundle] URLForResource:resourceName withExtension:@"jpg" subdirectory:@"IPSample"] path];
	
	UIImageView *returnedView =  [[[UIImageView alloc] initWithFrame:aPaginatedView.bounds] autorelease];
	returnedView.backgroundColor = [UIColor blackColor];
	returnedView.image = [UIImage imageWithContentsOfFile:resourceFilePath];
	returnedView.contentMode = UIViewContentModeScaleAspectFit;
	
	return returnedView;

}

- (UIViewController *) viewControllerForSubviewAtIndex:(NSUInteger)index inPaginatedView:(IRPaginatedView *)paginatedView {

	return nil;

}





- (void) viewDidUnload {

	self.paginatedView = nil;
	
	[super viewDidUnload];

}

- (void) dealloc {

	[managedObjectContext release];
	[article release];
	[paginatedView release];
	
	[super dealloc];

}

@end
