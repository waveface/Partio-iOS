//
//  WARepresentedFilePickerViewController.m
//  wammer
//
//  Created by Evadne Wu on 4/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WARepresentedFilePickerViewController.h"
#import "AQGridView.h"
#import "WADataStore.h"
#import "WAImageView.h"
#import "WACompositionViewPhotoCell.h"
#import "UIImage+IRAdditions.h"

@interface WARepresentedFilePickerViewController () <NSFetchedResultsControllerDelegate, AQGridViewDelegate, AQGridViewDataSource>
@property (nonatomic, strong) AQGridView *view;
@property (nonatomic, strong) NSURL *articleURI;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) WAArticle *article;
@property (nonatomic, copy) void (^callback)(NSURL *);
@end


@implementation WARepresentedFilePickerViewController
@dynamic view;
@synthesize articleURI, managedObjectContext, fetchedResultsController, article, callback;

+ (id) controllerWithObjectURI:(NSURL *)objectURI completion:(void (^)(NSURL *))block {

	WARepresentedFilePickerViewController *controller = [[self alloc] init];
	controller.articleURI = objectURI;
	controller.callback = block;
	
	return controller;

}

- (NSManagedObjectContext *) managedObjectContext {

	if (!managedObjectContext) {
		managedObjectContext = [[WADataStore defaultStore] defaultAutoUpdatedMOC];
	}
	
	return managedObjectContext;

}

- (NSFetchedResultsController *) fetchedResultsController {

	if (!fetchedResultsController) {
		
		NSFetchRequest *fetchRequest = [[WADataStore defaultStore] newFetchRequestForFilesInArticle:self.article];
		
		fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
		fetchedResultsController.delegate = self;
		
		NSError *fetchError = nil;
		if (![fetchedResultsController performFetch:&fetchError])
			NSLog(@"Error fetching: %@", fetchError);

	}

	return fetchedResultsController;

}

- (WAArticle *) article {

	if (!article) {
	
		article = (WAArticle *)[self.managedObjectContext irManagedObjectForURI:self.articleURI];
	
	}
	
	return article;

}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (!self)
		return nil;
	
	
	self.navigationItem.title = NSLocalizedString(@"CHANGE_REPRESENTING_FILE_TITLE", @"Title for Cover Image picker");
	//self.navigationItem.prompt = NSLocalizedString(@"CHANGE_REPRESENTING_FILE_PROMPT", @"Prompt for Cover Image picker");
	
	return self;

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
		
}

- (void) loadView {

	[self fetchedResultsController];	//	Although we don’t use it, we want change tracking to go on
	
	self.view = [[AQGridView alloc] initWithFrame:(CGRect){ 0, 0, 320, 320 }];
	self.view.backgroundColor = [UIColor whiteColor];
	self.view.dataSource = self;
	self.view.delegate = self;
	self.view.leftContentInset = 2;
	self.view.rightContentInset = 2;
	self.view.contentInset = (UIEdgeInsets){ 2, 0, 0, 0 };
	
	self.view.alwaysBounceVertical = YES;
	
	[self.view reloadData];

}

- (NSUInteger) numberOfItemsInGridView:(AQGridView *) gridView {

	return [self.article.files count];

}

- (AQGridViewCell *) gridView:(AQGridView *)gridView cellForItemAtIndex:(NSUInteger)index  {

	NSString * const identifier = @"Cell";
	WAFile *representedFile = [self itemAtIndex:index];
	WACompositionViewPhotoCell *cell = (WACompositionViewPhotoCell *)[gridView dequeueReusableCellWithIdentifier:identifier];
	
	if (![cell isKindOfClass:[WACompositionViewPhotoCell class]]) {
		cell = [[WACompositionViewPhotoCell alloc] initWithFrame:(CGRect){ CGPointZero, (CGSize){ 72.0f, 72.0f } } reuseIdentifier:identifier];
	}
	
	cell.canRemove = NO;
	cell.image = representedFile.smallestPresentableImage;
	cell.style = WACompositionViewPhotoCellBorderedPlainStyle;
	
	[cell setNeedsLayout];
	
	return cell;

}

- (CGSize) portraitGridCellSizeForGridView:(AQGridView *)aGV {

	return (CGSize){ 79.0f, 79.0f };

}

- (void) controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {

	if (![self isViewLoaded])
		return;
	
	switch (type) {
	
		case NSFetchedResultsChangeDelete:
		case NSFetchedResultsChangeInsert: {
			
			[self.view reloadData];
			break;

		}
		
		case NSFetchedResultsChangeMove: {
			
			break;
			
		}
		
		case NSFetchedResultsChangeUpdate: {
		
			//	do nothing, cell self updates
			break;
		
		}
	
	}

}

- (WAFile *) itemAtIndex:(NSUInteger)index {

	return [self.article.files objectAtIndex:index];

}

- (NSUInteger) indexOfItem:(WAFile *)aFile {

	return [self.article.files indexOfObject:aFile];

}

- (void) gridView:(AQGridView *)gridView didSelectItemAtIndex:(NSUInteger)index {
	
	WAFile *file = [self itemAtIndex:index];
	
	if (self.callback)
		self.callback([[file objectID] URIRepresentation]);

}

+ (NSSet *) keyPathsForValuesAffectingContentSizeForViewInPopover {

	return [NSSet setWithObjects:
	
		@"view.contentSize",
	
	nil];

}

- (CGSize) contentSizeForViewInPopover {

	return self.view.contentSize;

}

@end
