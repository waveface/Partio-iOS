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


@interface WAArticleViewController_Default () <AQGridViewDelegate, AQGridViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) AQGridView *gridView;

- (WAFile *) itemAtIndex:(NSUInteger)index;
- (NSUInteger) indexOfItem:(WAFile *)aFile;

@property (nonatomic, readwrite, assign) BOOL requiresGalleryReload;

@end


@implementation WAArticleViewController_Default
@synthesize fetchedResultsController, gridView, requiresGalleryReload;

- (void) dealloc {

	fetchedResultsController.delegate = nil;
	[fetchedResultsController release];
	[super dealloc];

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	UIView *gridViewWrapper = [[[UIView alloc] initWithFrame:self.gridView.bounds] autorelease];
	gridViewWrapper.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPhotoQueueBackground"]];
	
	self.gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.gridView.frame = CGRectInset(self.gridView.frame, 0, 16);
	[gridViewWrapper addSubview:self.gridView];
	
	IRGradientView *topShadow = [[IRGradientView alloc] initWithFrame:IRGravitize(gridViewWrapper.bounds, (CGSize){
		CGRectGetWidth(gridViewWrapper.bounds),
		6
	}, kCAGravityTop)];
	topShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
	[topShadow setLinearGradientFromColor:[UIColor colorWithWhite:0 alpha:0.25] anchor:irTop toColor:[UIColor colorWithWhite:0 alpha:0] anchor:irBottom];
	[gridViewWrapper addSubview:topShadow];
	
	IRGradientView *bottomShadow = [[IRGradientView alloc] initWithFrame:IRGravitize(gridViewWrapper.bounds, (CGSize){
		CGRectGetWidth(gridViewWrapper.bounds),
		6
	}, kCAGravityBottom)];
	bottomShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
	[bottomShadow setLinearGradientFromColor:[UIColor colorWithWhite:0 alpha:0] anchor:irTop toColor:[UIColor colorWithWhite:0 alpha:0.25] anchor:irBottom];
	[gridViewWrapper addSubview:bottomShadow];
		
	self.gridView.clipsToBounds = NO;
	gridViewWrapper.clipsToBounds = YES;
	
	[gridView reloadData];
	[gridView setNeedsLayout];
	
	[self.stackView addStackElementsObject:gridViewWrapper];
	
}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	
	[UIView animateWithDuration:0 delay:0 options:UIViewAnimationOptionOverrideInheritedCurve|UIViewAnimationOptionOverrideInheritedDuration animations:^{

		[self.stackView layoutSubviews];
		
	} completion:^(BOOL finished) {
	
		//	?
		
	}];
	
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
	fetchedResultsController.delegate = self;
	
	NSError *fetchError = nil;
	if (![fetchedResultsController performFetch:&fetchError])
		NSLog(@"Error fetching: %@", fetchError);
	
	return fetchedResultsController;

}

- (AQGridView *) gridView {

	if (gridView)
		return gridView;
	
	gridView = [[[AQGridView alloc] initWithFrame:(CGRect){ CGPointZero, (CGSize){ 320, 128 }}] autorelease];
	gridView.delegate = self;
	gridView.dataSource = self;
	
	gridView.bounces = YES;
	gridView.alwaysBounceVertical = YES;
	gridView.alwaysBounceHorizontal = NO;
	
	[gridView reloadData];
	[gridView setNeedsLayout];
	
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
		dequeuedCell.frame = (CGRect){ CGPointZero, [self portraitGridCellSizeForGridView:gridView] };
	}
	
	dequeuedCell.canRemove = NO;
	dequeuedCell.image = representedFile.thumbnailImage;
	[dequeuedCell setNeedsLayout];

	return dequeuedCell;
	
}

- (CGSize) portraitGridCellSizeForGridView:(AQGridView *)aGV {

	return (CGSize){ 240, 240 };

}

- (WAFile *) itemAtIndex:(NSUInteger)index {
	
	return (WAFile *)[self.article.managedObjectContext irManagedObjectForURI:[self.article.fileOrder objectAtIndex:index]];

}

- (NSUInteger) indexOfItem:(WAFile *)aFile {

	return [self.article.fileOrder indexOfObject:[[aFile objectID] URIRepresentation]];

}

- (void) controllerWillChangeContent:(NSFetchedResultsController *)controller {

	if (![self isViewLoaded])
		return;

	requiresGalleryReload = NO;

}

- (void) controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {

	NSParameterAssert(NO);

}

- (void) controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {

	if (![self isViewLoaded])
		return;
	
	if (requiresGalleryReload)
		return;

	if (![anObject isKindOfClass:[WAFile class]]) {
		requiresGalleryReload = YES;
		return;
	}
	
	NSUInteger ownIndex = [self indexOfItem:(WAFile *)anObject];
	if (ownIndex == NSNotFound) {
		requiresGalleryReload = YES;
		return;
	}
	
	WACompositionViewPhotoCell *currentCell = (WACompositionViewPhotoCell *)[gridView cellForItemAtIndex:ownIndex];
	if (![currentCell isKindOfClass:[WACompositionViewPhotoCell class]])
		return;	//	It will just show new stuff the next time it shows up
	
	currentCell.image = ((WAFile *)anObject).thumbnailImage;

}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {

	if (![self isViewLoaded])
		return;
	
	if (requiresGalleryReload)
		[gridView reloadData];

}

- (void) gridView:(AQGridView *)aGV didSelectItemAtIndex:(NSUInteger)index {

	__block WAGalleryViewController *galleryVC = nil;
	
	galleryVC = [WAGalleryViewController controllerRepresentingArticleAtURI:[[self.article objectID] URIRepresentation] context:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[[[self itemAtIndex:index] objectID] URIRepresentation], kWAGalleryViewControllerContextPreferredFileObjectURI,
	
	nil]];
	
	galleryVC.onDismiss = ^ {
		
		[galleryVC dismissModalViewControllerAnimated:NO];
		
	};
	
	[self presentModalViewController:galleryVC animated:NO];

}

- (BOOL) stackView:(WAStackView *)aStackView shouldStretchElement:(UIView *)anElement {

	if ((anElement == gridView) || [gridView isDescendantOfView:anElement])
		return YES;
	
	return [super stackView:aStackView shouldStretchElement:anElement];

}

- (CGSize) sizeThatFitsElement:(UIView *)anElement inStackView:(WAStackView *)aStackView {

	if ((anElement == gridView) || [gridView isDescendantOfView:anElement]) {
		return (CGSize){
			CGRectGetWidth(aStackView.bounds), 
			MAX(
				32 + 128, 
				MIN(
					CGRectGetHeight(aStackView.bounds),
					(gridView.numberOfRows + (!!(gridView.numberOfItems - gridView.numberOfRows * gridView.numberOfColumns) ? 1 : 0)) * 
						gridView.gridCellSize.height + 
						gridView.contentInset.top + gridView.contentInset.bottom + 32
				)
			)
		};
	}
	
	return [super sizeThatFitsElement:anElement inStackView:aStackView];

}

@end
