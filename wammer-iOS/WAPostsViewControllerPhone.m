//
//  WAArticlesViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WADataStore.h"
#import "WAPostsViewControllerPhone.h"
#import "WACompositionViewController.h"
#import "WAPaginationSlider.h"

#import "WARemoteInterface.h"

#import "IRPaginatedView.h"
#import "IRBarButtonItem.h"
#import "IRTransparentToolbar.h"
#import "IRActionSheetController.h"
#import "IRActionSheet.h"

#import "WAArticleViewController.h"
#import "WAPostViewControllerPhone.h"
#import "WAUserSelectionViewController.h"


@interface WAPostsViewControllerPhone () <NSFetchedResultsControllerDelegate>

@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;

- (void) refreshData;

@end


@implementation WAPostsViewControllerPhone
@synthesize fetchedResultsController;
@synthesize managedObjectContext;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self)
		return nil;
		
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Account" style:UIBarButtonItemStyleBordered target:self action:@selector(handleAccount:)] autorelease];
    self.title = @"Wammer";
    self.navigationItem.rightBarButtonItem  = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showPostView:)]autorelease];
    
	self.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	self.fetchedResultsController = [[[NSFetchedResultsController alloc] initWithFetchRequest:((^ {
	
		NSFetchRequest *returnedRequest = [[[NSFetchRequest alloc] init] autorelease];
		returnedRequest.entity = [NSEntityDescription entityForName:@"WAArticle" inManagedObjectContext:self.managedObjectContext];
		returnedRequest.predicate = [NSPredicate predicateWithFormat:@"ANY files.identifier != nil"]; // TBD files.thumbnailFilePath != nil
		returnedRequest.sortDescriptors = [NSArray arrayWithObjects:
			[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES],
		nil];
		
		return returnedRequest;
	
	})()) managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil] autorelease];
	
	self.fetchedResultsController.delegate = self;
		
	return self;

}

- (void) dealloc {
	
	[managedObjectContext release];
	[fetchedResultsController release];
	[super dealloc];

}

- (void) viewDidUnload {
	
	[super viewDidUnload];

}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	
	//	I am not really sure this works!
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		[self refreshData];
				
	});

}

- (void) viewWillDisappear:(BOOL)animated {

	[super viewWillDisappear:animated];
	
}

- (NSUInteger) numberOfViewsInPaginatedView:(IRPaginatedView *)paginatedView {

	return [[self.fetchedResultsController fetchedObjects] count];

}

- (void) handleAccount:(UIBarButtonItem *)sender {

    
    __block WAUserSelectionViewController *userSelectionVC = nil;
    userSelectionVC = [WAUserSelectionViewController controllerWithElectibleUsers:nil onSelection:^(NSURL *pickedUser) {
        
        NSManagedObjectContext *disposableContext = [[WADataStore defaultStore] disposableMOC];
        WAUser *userObject = (WAUser *)[disposableContext irManagedObjectForURI:pickedUser];
        NSString *userIdentifier = userObject.identifier;
        
        [[NSUserDefaults standardUserDefaults] setObject:userIdentifier forKey:@"WhoAmI"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [userSelectionVC.navigationController dismissModalViewControllerAnimated:YES];
        
    }];

    UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:userSelectionVC] autorelease];
	[self.navigationController presentModalViewController:nc animated:YES];
    
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)newOrientation {

	if ([[UIApplication sharedApplication] isIgnoringInteractionEvents])
		return (self.interfaceOrientation == newOrientation);

	return YES;
	
}

- (void) refreshData {

	[[WARemoteInterface sharedInterface] retrieveArticlesWithContinuation:nil batchLimit:200 onSuccess:^(NSArray *retrievedArticleReps) {
	
		NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
		
		[WAArticle insertOrUpdateObjectsUsingContext:context withRemoteResponse:retrievedArticleReps usingMapping:[NSDictionary dictionaryWithObjectsAndKeys:
			@"WAFile", @"files",
			@"WAComment", @"comments",
		nil] options:0];
		
		NSError *savingError = nil;
		if (![context save:&savingError])
			NSLog(@"Saving Error %@", savingError);
			
		dispatch_async(dispatch_get_main_queue(), ^ {
//			[self refreshPaginatedViewPages];
		});
		
	} onFailure:^(NSError *error) {
		
		NSLog(@"Fail %@", error);
		
	}];

}

- (void) controllerWillChangeContent:(NSFetchedResultsController *)controller {
	
	NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, [NSThread currentThread], controller);
	
}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
	
	NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, [NSThread currentThread], controller);
	
}

- (void) showPostView:(UIBarButtonItem *)sender
{
    WAPostViewControllerPhone *pvc = [[[WAPostViewControllerPhone alloc]init]autorelease];
    [self.navigationController pushViewController:pvc animated:YES];
}


@end
