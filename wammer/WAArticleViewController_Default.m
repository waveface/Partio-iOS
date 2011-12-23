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
	
	UIView *gridViewWrapper = [[[UIView alloc] initWithFrame:self.gridView.bounds] autorelease];
	gridViewWrapper.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPhotoQueueBackground"]];
	
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
	
	self.gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.gridView.frame = CGRectInset(self.gridView.frame, 0, 16);
	[gridViewWrapper addSubview:self.gridView];
	
	self.gridView.clipsToBounds = NO;
	gridViewWrapper.clipsToBounds = YES;
	
	[gridView reloadData];
	[gridView setNeedsLayout];
	
	[self.stackView addStackElementsObject:gridViewWrapper];
	
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
	
	gridView.leftContentInset = 64;
	gridView.rightContentInset = 64;
	
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

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {

	if (![self isViewLoaded])
		return;
	
	[self.gridView reloadData];

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
		return (CGSize){ CGRectGetWidth(aStackView.bounds), 32 + 128 };
	}
	
	return [super sizeThatFitsElement:anElement inStackView:aStackView];

}

@end
