//
//  WAArticleViewController_Default.m
//  wammer
//
//  Created by Evadne Wu on 12/22/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "WAArticleViewController_Default.h"
#import "AQGridView.h"

#import "WAArticleViewController+Subclasses.h"
#import "WACompositionViewPhotoCell.h"

#import "WAGalleryViewController.h"

#import "WAArticle.h"


@interface WAArticleViewController_Default () <AQGridViewDelegate, AQGridViewDataSource>

@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) AQGridView *gridView;

- (WAFile *) itemAtIndex:(NSUInteger)index;

@end


@implementation WAArticleViewController_Default
@synthesize fetchedResultsController, gridView;

- (void) dealloc {

	fetchedResultsController.delegate = nil;
	[fetchedResultsController release];
	[super dealloc];

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	[self.stackView addStackElementsObject:self.gridView];
	
}

- (NSFetchedResultsController *) fetchedResultsController {

	if (fetchedResultsController)
		return fetchedResultsController;
		
	NSFetchRequest *fetchRequest = [self.managedObjectContext.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRImagesForArticle" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
		self.article, @"Article",
	nil]];
	
	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
		[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES],
	nil];
	
	fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	
	NSError *fetchError = nil;
	if (![fetchedResultsController performFetch:&fetchError])
		NSLog(@"Error fetching: %@", fetchError);
	
	return fetchedResultsController;

}

- (AQGridView *) gridView {

	if (gridView)
		return gridView;
	
	gridView = [[[AQGridView alloc] initWithFrame:(CGRect){ CGPointZero, (CGSize){ 320, 320 }}] autorelease];
	gridView.delegate = self;
	gridView.dataSource = self;
	
	gridView.layer.borderColor = [UIColor redColor].CGColor;
	gridView.layer.borderWidth = 2;
	
	gridView.bounces = YES;
	gridView.alwaysBounceVertical = YES;
	gridView.alwaysBounceHorizontal = NO;
	
	[gridView reloadData];
	
	return gridView;

}

- (NSUInteger) numberOfItemsInGridView:(AQGridView *)gridView {

	return [[self.fetchedResultsController fetchedObjects] count];

}

- (AQGridViewCell *) gridView:(AQGridView *)aGV cellForItemAtIndex:(NSUInteger) index {

	WAFile *representedFile = [self itemAtIndex:index];

	NSString * const identifier = @"Cell";
	WACompositionViewPhotoCell *dequeuedCell = (WACompositionViewPhotoCell *)[aGV dequeueReusableCellWithIdentifier:identifier];
	if (!dequeuedCell) {
		dequeuedCell = [WACompositionViewPhotoCell cellRepresentingFile:representedFile reuseIdentifier:identifier];
	}
	
	dequeuedCell.canRemove = NO;
	dequeuedCell.image = representedFile.thumbnailImage;
	[dequeuedCell setNeedsLayout];

	return dequeuedCell;
	
}

- (CGSize) portraitGridCellSizeForGridView:(AQGridView *)aGV {

	return (CGSize){ 128, 128 };

}

- (WAFile *) itemAtIndex:(NSUInteger)index {
	
	return (WAFile *)[self.article.managedObjectContext irManagedObjectForURI:[self.article.fileOrder objectAtIndex:index]];

}

- (void) gridView:(AQGridView *)aGV didSelectItemAtIndex:(NSUInteger)index {

	__block WAGalleryViewController *galleryVC = nil;
	
	galleryVC = [WAGalleryViewController controllerRepresentingArticleAtURI:[[self.article objectID] URIRepresentation]];
	galleryVC.onDismiss = ^ {
		[galleryVC dismissModalViewControllerAnimated:NO];
	};
	
	[self presentModalViewController:galleryVC animated:NO];

}

- (BOOL) stackView:(WAStackView *)aStackView shouldStretchElement:(UIView *)anElement {

	if (anElement == gridView)
		return YES;
	
	return [super stackView:aStackView shouldStretchElement:anElement];

}

- (CGSize) sizeThatFitsElement:(UIView *)anElement inStackView:(WAStackView *)aStackView {

	if (anElement == gridView)
		return (CGSize){ CGRectGetWidth(aStackView.bounds), 128 };
	
	return [super sizeThatFitsElement:anElement inStackView:aStackView];

}

@end
