//
//  WACompositionViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WACompositionViewController.h"
#import "WADataStore.h"
#import "IRImagePickerController.h"


@interface WACompositionViewController () <AQGridViewDelegate, AQGridViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) WAArticle *article;
@property (nonatomic, readwrite, retain) UIPopoverController *imagePickerPopover;

- (void) handleCurrentArticleFilesChangedFrom:(id)fromValue to:(id)toValue changeKind:(NSString *)changeKind;
- (void) handleIncomingSelectedAssetURI:(NSURL *)aFileURL representedAsset:(ALAsset *)photoLibraryAsset;

@end


@implementation WACompositionViewController
@synthesize managedObjectContext, fetchedResultsController, article;
@synthesize photosView, contentTextView, toolbar;
@synthesize imagePickerPopover;

+ (WACompositionViewController *) controllerWithArticle:(NSURL *)anArticleURLOrNil completion:(void(^)(NSURL *anArticleURLOrNil))aBlock {

	WACompositionViewController *returnedController = [[[self alloc] init] autorelease];
	
	returnedController.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	returnedController.article = (WAArticle *)[returnedController.managedObjectContext irManagedObjectForURI:anArticleURLOrNil];
	
	if (!returnedController.article)
		returnedController.article = [WAArticle objectInsertingIntoContext:returnedController.managedObjectContext withRemoteDictionary:[NSDictionary dictionary]];
	
	return returnedController;
	
}

- (id) init {

	return [self initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];

}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	
	if (!self)
		return nil;
	
	self.title = @"Compose";
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(handleCancel:)] autorelease];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleDone:)] autorelease];
	
	return self;

}

- (void) setArticle:(WAArticle *)newArticle {

	__block __typeof__(self) nrSelf = self;

	[self willChangeValueForKey:@"article"];
	
	[article irRemoveObserverBlocksForKeyPath:@"files"];	
	[newArticle irAddObserverBlock:^(id inOldValue, id inNewValue, NSString *changeKind) {
		[nrSelf handleCurrentArticleFilesChangedFrom:inOldValue to:inNewValue changeKind:changeKind];
	} forKeyPath:@"files" options:NSKeyValueObservingOptionNew context:nil];	
	
	[article release];
	article = [newArticle retain];
	
	[self didChangeValueForKey:@"article"];

}

- (NSFetchedResultsController *) fetchedResultsController {

	if (fetchedResultsController)
		return fetchedResultsController;
	
	NSFetchRequest *fetchRequest = [self.managedObjectContext.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRFilesForArticle" substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
		self.article, @"Article",
	nil]];
	
	fetchRequest.returnsObjectsAsFaults = NO;
	
	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
		[NSSortDescriptor sortDescriptorWithKey:@"resourceURL" ascending:YES],
		[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES],
	nil];
		
	self.fetchedResultsController = [[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil] autorelease];
	self.fetchedResultsController.delegate = self;
	
	NSError *fetchingError;
	if (![self.fetchedResultsController performFetch:&fetchingError])
		NSLog(@"Error fetching: %@", fetchingError);
	
	return fetchedResultsController;

}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {

	NSLog(@"%s %@", __PRETTY_FUNCTION__, controller);

}

- (void) dealloc {

	[photosView release];
	[contentTextView release];
	[toolbar release];

	[article irRemoveObserverBlocksForKeyPath:@"files"];
	
	[managedObjectContext release];
	[fetchedResultsController release];
	[article release];
	[imagePickerPopover release];

	[super dealloc];

}

- (void) viewDidUnload {

	self.photosView = nil;
	self.contentTextView = nil;
	self.toolbar = nil;

	[super viewDidUnload];

}





- (void) viewDidLoad {

	[super viewDidLoad];
	
	if ([[UIDevice currentDevice].name rangeOfString:@"Simulator"].location != NSNotFound)
		self.contentTextView.autocorrectionType = UITextAutocorrectionTypeNo;
	
	self.contentTextView.text = self.article.text;
	
	self.toolbar.opaque = NO;
	self.toolbar.backgroundColor = [UIColor clearColor];
	
	self.photosView.layoutDirection = AQGridViewLayoutDirectionHorizontal;
	

}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];

	if (![[self.contentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
		[self.contentTextView becomeFirstResponder];

}





- (CGSize) portraitGridCellSizeForGridView: (AQGridView *) gridView {

	return (CGSize){ 144, 144 };

}

- (NSUInteger) numberOfItemsInGridView:(AQGridView *)gridView {

	return [self.fetchedResultsController.fetchedObjects count];

}

- (AQGridViewCell *) gridView:(AQGridView *)gridView cellForItemAtIndex:(NSUInteger)index {

	static NSString * const identifier = @"photoCell";
	
	AQGridViewCell *cell = [gridView dequeueReusableCellWithIdentifier:identifier];
	WAFile *representedFile = (WAFile *)[self.fetchedResultsController.fetchedObjects objectAtIndex:index];
	
	if (!cell) {
	
		cell = [[[AQGridViewCell alloc] initWithFrame:(CGRect){ 0, 0, 128, 128 } reuseIdentifier:identifier] autorelease];
		cell.selectionStyle = AQGridViewCellSelectionStyleNone;
	
	}
	
	cell.contentView.layer.contents = (id)[UIImage imageWithContentsOfFile:representedFile.resourceFilePath].CGImage;
	cell.contentView.layer.contentsGravity = kCAGravityResizeAspect;
	
	cell.contentView.layer.borderColor = [UIColor redColor].CGColor;
	cell.contentView.layer.borderWidth = 2.0f;
	
	return cell;

}

- (void) handleCurrentArticleFilesChangedFrom:(id)fromValue to:(id)toValue changeKind:(NSString *)changeKind {

	NSLog(@"%s %@ %@ %@", __PRETTY_FUNCTION__, fromValue, toValue, changeKind);
	
	dispatch_async(dispatch_get_main_queue(), ^ {
		[self.photosView reloadData];
	});

}





- (void) handleDone:(UIBarButtonItem *)sender {

	[self.article.managedObjectContext deleteObject:self.article];
	[self.article.managedObjectContext save:nil];

	[self dismissModalViewControllerAnimated:YES];

}	

- (void) handleCancel:(UIBarButtonItem *)sender {

	[self.article.managedObjectContext deleteObject:self.article];
	[self.article.managedObjectContext save:nil];
	
	[self dismissModalViewControllerAnimated:YES];

}

- (IBAction) handleCameraItemTap:(UIBarButtonItem *)sender {

	[self.imagePickerPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];

	//	?

}

- (UIPopoverController *) imagePickerPopover {

	if (imagePickerPopover)
		return imagePickerPopover;
		
	__block __typeof__(self) nrSelf = self;
		
	IRImagePickerController *imagePickerController = [IRImagePickerController photoLibraryPickerWithCompletionBlock:^(NSURL *selectedAssetURI, ALAsset *representedAsset) {
		
		[nrSelf handleIncomingSelectedAssetURI:selectedAssetURI representedAsset:representedAsset];
		
	}];
	
	self.imagePickerPopover = [[[UIPopoverController alloc] initWithContentViewController:imagePickerController] autorelease];
	
	return imagePickerPopover;

}

- (void) handleIncomingSelectedAssetURI:(NSURL *)selectedAssetURI representedAsset:(ALAsset *)representedAsset {
	
	if ([imagePickerPopover isPopoverVisible])
		[imagePickerPopover dismissPopoverAnimated:YES];
		
	dispatch_async(dispatch_get_global_queue(0, 0), ^ {

		NSURL *finalFileURL = nil;
		
		if (selectedAssetURI) {
		
			finalFileURL = [[WADataStore defaultStore] persistentFileURLForFileAtURL:selectedAssetURI];
		
		} else if (!selectedAssetURI && representedAsset) {
		
			finalFileURL = [[WADataStore defaultStore] persistentFileURLForData:UIImagePNGRepresentation([UIImage imageWithCGImage:[[representedAsset defaultRepresentation] fullResolutionImage]])];
				
		}
		
		dispatch_async(dispatch_get_main_queue(), ^ {
		
			WAFile *stitchedFile = (WAFile *)[WAFile objectInsertingIntoContext:self.managedObjectContext withRemoteDictionary:[NSDictionary dictionary]];
			stitchedFile.resourceType = (NSString *)kUTTypeImage;
			stitchedFile.resourceURL = [finalFileURL absoluteString];
			stitchedFile.resourceFilePath = [finalFileURL path];
			stitchedFile.article = self.article;
			
			[self.managedObjectContext save:nil];
		
		});
	
	});
	
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	return YES;
	
}

@end
