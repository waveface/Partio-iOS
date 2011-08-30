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

static NSString * const WAPostViewControllerPhone_RepresentedObjectURI = @"WAPostViewControllerPhone_RepresentedObjectURI";

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
        self.title = @"Post";
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
        //TODO the cell style need to use Image && Comment for settings rather than 4 different style which grows exponentially
      static NSString *defaultCellIdentifier = @"PostCell-Default";
      static NSString *imageCellIdentifier = @"PostCell-Stacked";
      
      BOOL postHasFiles = (BOOL)!![post.files count];
      
      NSString *identifier = postHasFiles ? imageCellIdentifier : defaultCellIdentifier;
      
      WAPostViewCellStyle style = postHasFiles ? WAPostViewCellStyleImageStack : WAPostViewCellStyleDefault;
      
      WAPostViewCellPhone *cell = (WAPostViewCellPhone *)[tableView dequeueReusableCellWithIdentifier:identifier];
      if(!cell) {
        cell = [[WAPostViewCellPhone alloc] initWithPostViewCellStyle:style reuseIdentifier:identifier];
        cell.imageStackView.delegate = self;
      }
      
      NSLog(@"Post ID: %@ with WAPostViewCellStyle %d and Text %@", [post identifier], style, post.text);
      cell.userNicknameLabel.text = post.owner.nickname;
      cell.avatarView.image = post.owner.avatar;
      cell.contentTextLabel.text = post.text;
      cell.dateLabel.text = [NSString stringWithFormat:@"%@ %@", 
                             [[[self class] relativeDateFormatter] stringFromDate:post.timestamp], 
                             [NSString stringWithFormat:@"via %@", post.creationDeviceName]];
      cell.originLabel.text = [NSString stringWithFormat:@"via %@", post.creationDeviceName];
      [cell setCommentCount:[post.comments count]];
      
      if (cell.imageStackView)
        objc_setAssociatedObject(cell.imageStackView, &WAPostViewControllerPhone_RepresentedObjectURI, [[post objectID] URIRepresentation], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      
      NSArray *allFilePaths = [post.fileOrder irMap: ^ (id inObject, int index, BOOL *stop) {
        
        return ((WAFile *)[[post.files objectsPassingTest: ^ (WAFile *aFile, BOOL *stop) {		
          return [[[aFile objectID] URIRepresentation] isEqual:inObject];
        }] anyObject]).resourceFilePath;
        
      }];
      
      if ([allFilePaths count] == [post.files count]) {
        
        cell.imageStackView.images = [allFilePaths irMap: ^ (NSString *aPath, int index, BOOL *stop) {
          
          return [UIImage imageWithContentsOfFile:aPath];
          
        }];
        
      } else {
        cell.imageStackView.images = nil;
      }
      
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
	cell.dateLabel.text = [[[self class] relativeDateFormatter] stringFromDate:post.timestamp];

    [representedComment.timestamp description];
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
  NSString *text = [self.post text];
  CGFloat height = [text sizeWithFont:[UIFont fontWithName:@"Helvetica" size:14.0] constrainedToSize:CGSizeMake(240.0, 9999.0) lineBreakMode:UILineBreakModeWordWrap].height;
  if([indexPath section]==0){
     height += (48.0); // Header
    if( [post.files count ] > 0)
      height += 170.0;
    
    if( [post.comments count] > 0)
      height += 40.0; 
    
    return height;
  }else{
    height +=12.0;
  }
  return height;
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
