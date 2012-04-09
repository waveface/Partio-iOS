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
	gridView.delegate = nil;

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	UIView *gridViewWrapper = [[UIView alloc] initWithFrame:self.gridView.bounds];
	gridViewWrapper.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPhotoQueueBackground"]];
	[gridViewWrapper addSubview:self.gridView];
	
	self.gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	
	IRGradientView *topShadow = [[IRGradientView alloc] initWithFrame:IRGravitize(gridViewWrapper.bounds, (CGSize){
		CGRectGetWidth(gridViewWrapper.bounds),
		3
	}, kCAGravityTop)];
	topShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
	[topShadow setLinearGradientFromColor:[UIColor colorWithWhite:0 alpha:0.125] anchor:irTop toColor:[UIColor colorWithWhite:0 alpha:0] anchor:irBottom];
	[gridViewWrapper addSubview:topShadow];
	
	IRGradientView *bottomShadow = [[IRGradientView alloc] initWithFrame:IRGravitize(gridViewWrapper.bounds, (CGSize){
		CGRectGetWidth(gridViewWrapper.bounds),
		3
	}, kCAGravityBottom)];
	bottomShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
	[bottomShadow setLinearGradientFromColor:[UIColor colorWithWhite:0 alpha:0] anchor:irTop toColor:[UIColor colorWithWhite:0 alpha:0.125] anchor:irBottom];
	[gridViewWrapper addSubview:bottomShadow];
		
	self.gridView.clipsToBounds = NO;
	gridViewWrapper.clipsToBounds = YES;
	
	NSMutableArray *allStackElements = [self.stackView mutableStackElements];

	UIView *footerCell = self.footerCell;
	if ([allStackElements containsObject:footerCell]) {
		[allStackElements removeObject:footerCell];
	}
	
	[allStackElements addObject:gridViewWrapper];
	
//	if (footerCell)
//		[allStackElements addObject:footerCell];
	
}

- (void) viewDidUnload {
	
	self.gridView = nil;
	
	[super viewDidUnload];

}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	
	if ([UIViewController respondsToSelector:@selector(attemptRotationToDeviceOrientation)])
		[UIViewController performSelector:@selector(attemptRotationToDeviceOrientation)];
		
	for (UIWindow *aWindow in [UIApplication sharedApplication].windows) {
	
		UIViewController *rootVC = aWindow.rootViewController;
		if ([rootVC isViewLoaded])
			[rootVC.view layoutSubviews];
		
		UINavigationController *rootNavC = [rootVC isKindOfClass:[UINavigationController class]] ? (UINavigationController *)rootVC : nil;
		if (rootNavC) {
			BOOL navBarHidden = rootNavC.navigationBarHidden;
			[rootNavC setNavigationBarHidden:YES animated:NO];
			[rootNavC setNavigationBarHidden:NO animated:NO];
			[rootNavC setNavigationBarHidden:YES animated:NO];
			[rootNavC setNavigationBarHidden:navBarHidden animated:NO];
		}
	
	}
		
}

- (void) viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];
	
	[self.stackView layoutSubviews];
	[self.gridView reloadData];

}

- (NSFetchedResultsController *) fetchedResultsController {

	if (fetchedResultsController)
		return fetchedResultsController;
		
	NSFetchRequest *fetchRequest = [[WADataStore defaultStore] newFetchRequestForFilesInArticle:self.article];
	
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
	
	gridView = [[AQGridView alloc] initWithFrame:(CGRect){ CGPointZero, (CGSize){ 320, 128 }}];
	gridView.delegate = self;
	gridView.dataSource = self;
	
	gridView.bounces = YES;
	gridView.alwaysBounceVertical = YES;
	gridView.alwaysBounceHorizontal = NO;
	
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
	
	dequeuedCell.frame = (CGRect){ CGPointZero, [self portraitGridCellSizeForGridView:gridView] };
	dequeuedCell.canRemove = NO;
	dequeuedCell.image = representedFile.thumbnailImage;
	[dequeuedCell setNeedsLayout];
	
	return dequeuedCell;
	
}

- (CGSize) portraitGridCellSizeForGridView:(AQGridView *)aGV {

	CGRect gvBounds = aGV.bounds;
	CGFloat gvWidth = CGRectGetWidth(gvBounds), gvHeight = CGRectGetHeight(gvBounds);
	
	NSUInteger numberOfItems = [self.article.fileOrder count];
	if (numberOfItems > 4) {
	
		CGFloat edgeLength = floorf(gvWidth / 3);
		return (CGSize){ edgeLength, edgeLength };
		
	} else if (numberOfItems > 1) {
		
		CGFloat edgeLength = floorf(gvWidth / 2);
		return (CGSize){ edgeLength, edgeLength };
		
	} else {
		
		CGFloat edgeLength = MIN(gvWidth, gvHeight);
		return (CGSize){ edgeLength, edgeLength };
		
	}
	
}

- (WAFile *) itemAtIndex:(NSUInteger)index {

	if (index >= [self.article.fileOrder count])
		return nil;
	
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

	__weak WAGalleryViewController *galleryVC = nil;
	
	galleryVC = [WAGalleryViewController controllerRepresentingArticleAtURI:[[self.article objectID] URIRepresentation] context:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[[[self itemAtIndex:index] objectID] URIRepresentation], kWAGalleryViewControllerContextPreferredFileObjectURI,
	
	nil]];
	
	galleryVC.onDismiss = ^ {
		
		[galleryVC dismissModalViewControllerAnimated:NO];
		
	};
	
	[self presentModalViewController:galleryVC animated:NO];
	[aGV deselectItemAtIndex:index animated:NO];

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
			128	//	Stretchable
		};
	}
	
	return [super sizeThatFitsElement:anElement inStackView:aStackView];

}

- (UIView *) scrollableStackElementWrapper {

	return self.gridView.superview;

}

- (UIScrollView *) scrollableStackElement {

	return self.gridView;

}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
		
	[self.gridView reloadData];
	[self.gridView layoutSubviews];

}

- (BOOL) enablesTextStackElementFolding {

	return YES;

}

@end
