//
//  WAArticleDraftsViewController.m
//  wammer
//
//  Created by Evadne Wu on 11/18/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAArticleDraftsViewController.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"


@interface WAArticleDraftsViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;

@end


@implementation WAArticleDraftsViewController
@synthesize fetchedResultsController, delegate;

- (id) initWithStyle:(UITableViewStyle)style {
  
  self = [super initWithStyle:style];
  if (!self)
    return nil;
  
  self.title = NSLocalizedString(@"NOUN_DRAFTS", @"Plural noun for draft objects");
  
  NSFetchRequest *fr = [[[WADataStore defaultStore] managedObjectModel] fetchRequestFromTemplateWithName:@"WAFRArticleDrafts" substitutionVariables:[NSDictionary dictionary]];
  NSManagedObjectContext *moc = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
  
  fr.sortDescriptors = [NSArray arrayWithObjects:
    [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO],
  nil];
  
  fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fr managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
  fetchedResultsController.delegate = self;
  
  return self;
  
}

- (void) dealloc {

	fetchedResultsController.delegate = nil;

}

- (void) viewDidLoad {

  [super viewDidLoad];
  
  self.tableView.rowHeight = 56.0f;

  NSError *fetchingError = nil;
  [self.fetchedResultsController performFetch:&fetchingError];

  self.navigationItem.rightBarButtonItem = self.editButtonItem;

}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {

  if ([self isViewLoaded])
    [self.tableView reloadData];

}

- (void) viewWillAppear:(BOOL)animated {

  [super viewWillAppear:animated];
  
  [self.tableView reloadData];

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  
  return YES;
  
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
  
  return 1 + [[self.fetchedResultsController sections] count];
  
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

  if (section == 0)
    return 1;
  
  return [[[self.fetchedResultsController sections] objectAtIndex:(section - 1)] numberOfObjects];
  
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  if (indexPath.section == 0) {
  
    static NSString *ActionCellIdentifier = @"ActionCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ActionCellIdentifier];
    if (!cell) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ActionCellIdentifier];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.text = NSLocalizedString(@"ACTION_NEW_POST", @"Action title for creating a new post");
    
    return cell;
  
  }

  static NSString *DraftCellIdentifier = @"DraftCell";
  
  NSIndexPath *actualIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:(indexPath.section - 1)];
  WAArticle *representedDraft = [self.fetchedResultsController objectAtIndexPath:actualIndexPath];

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DraftCellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:DraftCellIdentifier];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
   
  if (representedDraft.text)
    cell.textLabel.text = representedDraft.text;
  else
    cell.textLabel.text = NSLocalizedString(@"DRAFT_STATE_NO_CONTENT", @"State for drafts without content text");
  
  if (representedDraft.timestamp)
    cell.detailTextLabel.text = [[IRRelativeDateFormatter sharedFormatter] stringFromDate:representedDraft.timestamp];
  else
    cell.detailTextLabel.text = NSLocalizedString(@"DRAFT_STATE_NO_TIMESTAMP", @"State for drafts without a timestamp");
	
	BOOL cellEnabled = [self.delegate articleDraftsViewController:self shouldEnableArticle:[[representedDraft objectID] URIRepresentation]];
	if (cellEnabled) {
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.contentView.alpha = 1.0f;
	} else {
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.contentView.alpha = 0.5f;
	}
  
  return cell;
  
}

- (CGFloat) tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

  if (indexPath.section == 0)
    return 44.0;
  
  return aTableView.rowHeight;

}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

  if (section == 0)
    return NSLocalizedString(@"NOUN_ACTIONS_OBJECT", @"Singluar noun for action objects");
  
  if (section == 1)
    return NSLocalizedString(@"NOUN_DRAFTS", @"Plural noun for draft objects");
  
  return nil;

}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {

  if (indexPath.section == 0)
    return UITableViewCellEditingStyleNone;
  
  NSIndexPath *actualIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:(indexPath.section - 1)];
  WAArticle *selectedArticle = [self.fetchedResultsController objectAtIndexPath:actualIndexPath];
  NSURL *articleURI = [[selectedArticle objectID] URIRepresentation];
	
	BOOL cellEnabled = [self.delegate articleDraftsViewController:self shouldEnableArticle:articleURI];
	if (!cellEnabled)
		return UITableViewCellEditingStyleNone;
	
	return UITableViewCellEditingStyleDelete;

}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

  NSIndexPath *actualIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:(indexPath.section - 1)];
  WAArticle *deletedArticle = [self.fetchedResultsController objectAtIndexPath:actualIndexPath];
  
  [self.tableView beginUpdates];
  [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
  [self.fetchedResultsController.managedObjectContext deleteObject:deletedArticle];
  [self.fetchedResultsController performFetch:nil];
  [self.tableView endUpdates];
  
  [self.fetchedResultsController.managedObjectContext save:nil];

}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  if (indexPath.section == 0) {
    [self.delegate articleDraftsViewController:self didSelectArticle:nil];
    return;
  }

  NSIndexPath *actualIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:(indexPath.section - 1)];
  WAArticle *selectedArticle = [self.fetchedResultsController objectAtIndexPath:actualIndexPath];
  NSURL *articleURI = [[selectedArticle objectID] URIRepresentation];
  
	BOOL cellEnabled = [self.delegate articleDraftsViewController:self shouldEnableArticle:articleURI];
	if (!cellEnabled)
		return;
	
  [self.delegate articleDraftsViewController:self didSelectArticle:articleURI];

}

@end
