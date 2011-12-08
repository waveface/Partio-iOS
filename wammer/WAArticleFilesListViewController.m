//
//  WAArticleFilesListViewController.m
//  wammer
//
//  Created by Evadne Wu on 12/2/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAArticleFilesListViewController.h"
#import "WADataStore.h"

#import "WASingleFileViewController.h"
#import "WAFile+QuickLook.h"

@interface WAArticleFilesListViewController () <NSFetchedResultsControllerDelegate, QLPreviewControllerDataSource>

@property (nonatomic, readwrite, retain) NSURL *articleURL;

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) WAArticle *article;

@end


@implementation WAArticleFilesListViewController

@synthesize articleURL;
@synthesize managedObjectContext;
@synthesize fetchedResultsController;
@synthesize article;

+ (id) controllerWithArticle:(NSURL *)anURI {

  WAArticleFilesListViewController *returnedController = [[[self alloc] init] autorelease];
  returnedController.articleURL = anURI;
  
  return returnedController;

}

- (void) viewDidLoad {

  [super viewDidLoad];

}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
  
  return [[self.fetchedResultsController sections] count];
  
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  
  return [((id<NSFetchedResultsSectionInfo>)[self.fetchedResultsController.sections objectAtIndex:section]) numberOfObjects];

}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (!cell) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
  }
  
  WAFile *representedFile = (WAFile *)([self.article.managedObjectContext irManagedObjectForURI:[self.article.fileOrder objectAtIndex:indexPath.row]]);
  cell.imageView.image = representedFile.thumbnailImage;
  cell.textLabel.text = [NSString stringWithFormat:@"File (%@; %@)", representedFile.resourceType, representedFile.resourceURL];
    
  return cell;
  
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  NSURL *fileURI = [self.article.fileOrder objectAtIndex:indexPath.row];
  WAFile *representedFile = (WAFile *)([self.article.managedObjectContext irManagedObjectForURI:fileURI]);
    
  __block WASingleFileViewController *previewController = [WASingleFileViewController controllerForFile:fileURI];
  previewController.onFinishLoad = [[previewController class] defaultQuickLookFinishLoadHandler];
  
  [self.navigationController pushViewController:previewController animated:YES];

}

- (NSInteger) numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {

  return [self.article.fileOrder count];

}

- (id <QLPreviewItem>) previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {

  WAFile *representedFile = (WAFile *)([self.article.managedObjectContext irManagedObjectForURI:[self.article.fileOrder objectAtIndex:index]]);
  return representedFile;

}

- (NSManagedObjectContext *) managedObjectContext {

  if (managedObjectContext)
    return managedObjectContext;
  
  managedObjectContext = [[[WADataStore defaultStore] defaultAutoUpdatedMOC] retain];
  return managedObjectContext;

}

- (NSFetchedResultsController *) fetchedResultsController {

  if (fetchedResultsController)
    return fetchedResultsController;
  
  fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:((^ {
    
    NSFetchRequest *returnedFetchRequest = [self.managedObjectContext.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRFilesForArticle" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
    
      self.article, @"Article",
      
    nil]];
    
    returnedFetchRequest.sortDescriptors = [NSArray arrayWithObjects:
      
      [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES],
      
    nil];
    
    return returnedFetchRequest;
    
  })()) managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
  
  fetchedResultsController.delegate = self;
  
  [fetchedResultsController performFetch:nil];
  
  return fetchedResultsController;

}

- (WAArticle *) article {

  if (article)
    return article;
  
  return (WAArticle *)[self.managedObjectContext irManagedObjectForURI:self.articleURL];

}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {

  [self.tableView reloadData];

}

- (void) viewDidUnload {

  //  self.fetchedResultsController = nil;
  //  self.article = nil;
  //  self.managedObjectContext = nil;
  
  [super viewDidUnload];

}

- (void) dealloc {

  [fetchedResultsController release];
  [article release];
  [managedObjectContext release];
  [articleURL release];
  
  [super dealloc];

}

@end
