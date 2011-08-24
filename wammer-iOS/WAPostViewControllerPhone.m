//
//  WAPostViewController.m
//  wammer-iOS
//
//  Created by jamie on 8/11/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAPostViewControllerPhone.h"
#import "WAComposeViewControllerPhone.h"
#import "WADataStore.h"
#import "WAArticleCommentsViewCell.h"
#import "WAPostViewCellPhone.h"
#import "WAArticle.h"

@interface WAPostViewControllerPhone () <NSFetchedResultsControllerDelegate>

@property (nonatomic, readwrite, retain) WAArticle *post;
@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;

- (void) refreshData;

+ (IRRelativeDateFormatter *) relativeDateFormatter;


@end

@implementation WAPostViewControllerPhone
@synthesize post, fetchedResultsController, managedObjectContext;

+ (WAPostViewControllerPhone *) controllerWithPost:(NSURL *)postURL{
    
    WAPostViewControllerPhone *controller = [[self alloc] initWithStyle:UITableViewStylePlain];
    
    controller.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
    controller.post = (WAArticle *)[controller.managedObjectContext irManagedObjectForURI:postURL];
    
    return controller;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.title = @"Comments";
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(showCompose:)]autorelease];
        
    }
    return self;
}

- (NSFetchedResultsController *) fetchedResultsController {
    
	if (fetchedResultsController)
		return fetchedResultsController;
	
	if (!self.post)
		return nil;
    
	NSFetchRequest *fetchRequest = [self.managedObjectContext.persistentStoreCoordinator.managedObjectModel 
                                    fetchRequestFromTemplateWithName:@"WAFRCommentsForArticle" 
                                    substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:self.post, @"Article",nil]];
	
	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
                                    [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES],
                                    nil];
	
	self.fetchedResultsController = [[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil] autorelease];
	
	self.fetchedResultsController.delegate = self;
	
	NSError *fetchingError = nil;
	if (![fetchedResultsController performFetch:&fetchingError])
		NSLog(@"Error fetching: %@", fetchingError);
	
	return fetchedResultsController;
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)showCompose:(UIBarButtonItem *)sender
{
    [self.navigationController pushViewController:[[WAComposeViewControllerPhone alloc]init] animated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.post && !self.fetchedResultsController.fetchedObjects) {
		NSError *fetchingError = nil;
		if (![self.fetchedResultsController performFetch:&fetchingError])
			NSLog(@"Error fetching: %@", fetchingError);
		else
			[self refreshData];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)
        return 1;
    else
        return [[[self post] comments] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Section 0 for post cell
    if( [indexPath section] == 0) {
        WAPostViewCellPhone *cell = (WAPostViewCellPhone *)[tableView dequeueReusableCellWithIdentifier:@"Post"];
        if (cell == nil) {
            cell = [[[WAPostViewCellPhone alloc] initWithStyle:WAPostViewCellStyleCompact reuseIdentifier:@"Post"] autorelease];
        }
    
        cell.userNicknameLabel.text = post.owner.nickname;
        cell.avatarView.image = post.owner.avatar;
        cell.contentTextLabel.text = post.text;
        //cell.dateLabel.text = [[[self class] relativeDateFormatter] stringFromDate:post.timestamp];
        cell.originLabel.text = [NSString stringWithFormat:@"via %@", post.creationDeviceName];
        return cell;
    }
    
    // Section 2 for comment cell
    NSIndexPath *commentIndexPath = [NSIndexPath indexPathForRow:[indexPath row] inSection:0];
    WAComment *representedComment = (WAComment *)[self.fetchedResultsController objectAtIndexPath:commentIndexPath];
	
	WAArticleCommentsViewCell *cell = (WAArticleCommentsViewCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (!cell)
		cell = [[[WAArticleCommentsViewCell alloc] initWithCommentsViewCellStyle:WAArticleCommentsViewCellStyleDefault reuseIdentifier:@"Cell"] autorelease];
    
	cell.userNicknameLabel.text = representedComment.owner.nickname;
	cell.avatarView.image = representedComment.owner.avatar;
	cell.contentTextLabel.text = representedComment.text;
	cell.dateLabel.text = [representedComment.timestamp description];
	cell.originLabel.text = representedComment.creationDeviceName;
	
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 150;
}


@end
