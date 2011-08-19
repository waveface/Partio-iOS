//
//  WAArticlesViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
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

#import "WAArticleCommentsViewCell.h"
#import "WAPostViewCellPhone.h"


@interface WAPostsViewControllerPhone () <NSFetchedResultsControllerDelegate>

@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;

- (void) refreshData;

+ (IRRelativeDateFormatter *) relativeDateFormatter;

@end


@implementation WAPostsViewControllerPhone
@synthesize fetchedResultsController;
@synthesize managedObjectContext;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self)
		return nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
		
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Account" style:UIBarButtonItemStyleBordered target:self action:@selector(handleAccount:)] autorelease];
    self.title = @"Wammer";
    self.navigationItem.rightBarButtonItem  = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(showPostView:)]autorelease];
    
	self.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	self.fetchedResultsController = [[[NSFetchedResultsController alloc] initWithFetchRequest:((^ {
        
		NSFetchRequest *returnedRequest = [[[NSFetchRequest alloc] init] autorelease];
		returnedRequest.entity = [NSEntityDescription entityForName:@"WAArticle" inManagedObjectContext:self.managedObjectContext];
		returnedRequest.predicate = [NSPredicate predicateWithFormat:@"(self != nil) AND (draft == NO)"]; //	@"ANY files.identifier != nil"]; // TBD files.thumbnailFilePath != nil
		returnedRequest.sortDescriptors = [NSArray arrayWithObjects:
                                           [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES],
                                           nil];
		
		return returnedRequest;
        
	})()) managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil] autorelease];
	
	self.fetchedResultsController.delegate = self;
    
    
    NSError *error;
	[self.fetchedResultsController performFetch:&error];
    
	return self;

}

- (void) handleManagedObjectContextDidSave:(NSNotification *)aNotification {
    
	NSManagedObjectContext *savedContext = (NSManagedObjectContext *)[aNotification object];
	
	if (savedContext == self.managedObjectContext)
		return;
	
	dispatch_async(dispatch_get_main_queue(), ^ {
        
		[self.managedObjectContext mergeChangesFromContextDidSaveNotification:aNotification];
        
	});
    
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

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    if (!self.fetchedResultsController.fetchedObjects) {
        return 0;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(!self.fetchedResultsController.fetchedObjects)
        return 0;
    return [[self.fetchedResultsController.sections objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"PostCell";
    WAPostViewCellPhone *cell = (WAPostViewCellPhone *)[tableView dequeueReusableCellWithIdentifier:identifier];
    if(!cell) {
        cell = [[WAPostViewCellPhone alloc] initWithStyle:WAPostViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if(!post){
        NSLog(@"No posts");
    }
    
    cell.userNicknameLabel.text = post.owner.nickname;
    cell.avatarView.image = post.owner.avatar;
    cell.contentTextLabel.text = post.text;
    cell.dateLabel.text = [NSString stringWithFormat:@"%@ %@", 
                           [[[self class] relativeDateFormatter] stringFromDate:post.timestamp], 
                           [NSString stringWithFormat:@"via %@", post.creationDeviceName]];
    cell.originLabel.text = [NSString stringWithFormat:@"via %@", post.creationDeviceName];
    cell.extraInfoButton.titleLabel.text = [NSString stringWithFormat:@"%@ comments", @"0"];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 160;
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

	[[WADataStore defaultStore] updateUsersWithCompletion:nil];
	[[WADataStore defaultStore] updateArticlesWithCompletion:nil];

}

- (void) controllerWillChangeContent:(NSFetchedResultsController *)controller {
	
	NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, [NSThread currentThread], controller);
	
}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
	
	NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, [NSThread currentThread], controller);
    [self.tableView reloadData];

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    WAArticle *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
    WAPostViewControllerPhone *controller = [WAPostViewControllerPhone controllerWithPost:[[post objectID] URIRepresentation]];
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (void) showPostView:(UIBarButtonItem *)sender
{
    WAPostViewControllerPhone *pvc = [[[WAPostViewControllerPhone alloc]init]autorelease];
    [self.navigationController pushViewController:pvc animated:YES];
}

+ (IRRelativeDateFormatter *) relativeDateFormatter {
    
	static IRRelativeDateFormatter *formatter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
        
		formatter = [[IRRelativeDateFormatter alloc] init];
		formatter.approximationMaxTokenCount = 1;
        
	});
    
	return formatter;
    
}

@end
