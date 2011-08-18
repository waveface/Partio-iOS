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
#import "IRConcaveView.h"
#import "IRActionSheetController.h"
#import "IRActionSheet.h"
#import "WACompositionViewPhotoCell.h"


@interface WACompositionViewController () <AQGridViewDelegate, AQGridViewDataSource>

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) WAArticle *article;
@property (nonatomic, readwrite, retain) UIPopoverController *imagePickerPopover;

@property (nonatomic, readwrite, copy) void (^completionBlock)(NSURL *returnedURI);

- (void) handleCurrentArticleFilesChangedFrom:(id)fromValue to:(id)toValue changeKind:(NSString *)changeKind;
- (void) handleIncomingSelectedAssetURI:(NSURL *)aFileURL representedAsset:(ALAsset *)photoLibraryAsset;

@end


@implementation WACompositionViewController
@synthesize managedObjectContext, article;
@synthesize photosView, contentTextView, toolbar;
@synthesize imagePickerPopover;
@synthesize noPhotoReminderView;
@synthesize completionBlock;

+ (WACompositionViewController *) controllerWithArticle:(NSURL *)anArticleURLOrNil completion:(void(^)(NSURL *anArticleURLOrNil))aBlock {

	WACompositionViewController *returnedController = [[[self alloc] init] autorelease];
	
	returnedController.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	returnedController.article = (WAArticle *)[returnedController.managedObjectContext irManagedObjectForURI:anArticleURLOrNil];
	
	if (!returnedController.article) {
		returnedController.article = [WAArticle objectInsertingIntoContext:returnedController.managedObjectContext withRemoteDictionary:[NSDictionary dictionary]];
		returnedController.article.draft = [NSNumber numberWithBool:YES];
	}
	
	returnedController.completionBlock = aBlock;
	
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
	} forKeyPath:@"fileOrder" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];	
	
	[article release];
	article = [newArticle retain];
	
	[self didChangeValueForKey:@"article"];

}

- (void) dealloc {

	[photosView release];
	[contentTextView release];
	[noPhotoReminderView release];
	[toolbar release];

	[article irRemoveObserverBlocksForKeyPath:@"fileOrder"];
	
	[managedObjectContext release];
	[article release];
	[imagePickerPopover release];
	
	[completionBlock release];

	[super dealloc];

}

- (void) viewDidUnload {

	self.photosView = nil;
	self.noPhotoReminderView = nil;
	self.contentTextView = nil;
	self.toolbar = nil;
	self.imagePickerPopover = nil;

	[super viewDidUnload];

}





- (void) viewDidLoad {

	[super viewDidLoad];
	
	if ([[UIDevice currentDevice].name rangeOfString:@"Simulator"].location != NSNotFound)
		self.contentTextView.autocorrectionType = UITextAutocorrectionTypeNo;
	
	self.view.backgroundColor = [UIColor colorWithWhite:0.98f alpha:1.0f];
	
	self.contentTextView.text = self.article.text;
	
	self.toolbar.opaque = NO;
	self.toolbar.backgroundColor = [UIColor clearColor];
	
	self.photosView.layoutDirection = AQGridViewLayoutDirectionHorizontal;
	self.photosView.backgroundColor = nil;
	self.photosView.layer.cornerRadius = 4.0f;
	self.photosView.opaque = NO;
	self.photosView.bounces = YES;
	self.photosView.clipsToBounds = NO;
	self.photosView.alwaysBounceHorizontal = YES;
	self.photosView.alwaysBounceVertical = NO;
	self.photosView.directionalLockEnabled = YES;
	self.photosView.contentSizeGrowsToFillBounds = NO;
	self.photosView.showsVerticalScrollIndicator = NO;
	self.photosView.showsHorizontalScrollIndicator = NO;
	self.photosView.leftContentInset = 8.0f;
	
	self.noPhotoReminderView.frame = self.photosView.frame;
	self.noPhotoReminderView.autoresizingMask = self.photosView.autoresizingMask;
	[self.view addSubview:self.noPhotoReminderView];
	
	UIView *photosBackgroundView = [[[UIView alloc] initWithFrame:self.photosView.frame] autorelease];
	photosBackgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPhotoQueueBackground"]];
	photosBackgroundView.autoresizingMask = self.photosView.autoresizingMask;
	photosBackgroundView.frame = UIEdgeInsetsInsetRect(photosBackgroundView.frame, (UIEdgeInsets){ -20, -20, -40, -20 });
	photosBackgroundView.layer.masksToBounds = YES;
	photosBackgroundView.userInteractionEnabled = NO;
	[self.view insertSubview:photosBackgroundView atIndex:0];
	
	IRConcaveView *photosConcaveEdgeView = [[[IRConcaveView alloc] initWithFrame:self.photosView.frame] autorelease];
	photosConcaveEdgeView.autoresizingMask = self.photosView.autoresizingMask;
	photosConcaveEdgeView.backgroundColor = nil;
	photosConcaveEdgeView.frame = UIEdgeInsetsInsetRect(photosConcaveEdgeView.frame, (UIEdgeInsets){ -20, -20, -40, -20 });
	photosConcaveEdgeView.innerShadow = [IRShadow shadowWithColor:[UIColor colorWithWhite:0.0f alpha:0.5f] offset:(CGSize){ 0.0f, -1.0f } spread:3.0f];
	photosConcaveEdgeView.layer.masksToBounds = YES;
	photosConcaveEdgeView.userInteractionEnabled = NO;
	[self.view addSubview:photosConcaveEdgeView];
	
	self.photosView.contentInset = (UIEdgeInsets){ 0, 20, 42, 20 };
	objc_setAssociatedObject(self.photosView, @"defaultInsets", [NSValue valueWithUIEdgeInsets:self.photosView.contentInset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	self.photosView.frame = UIEdgeInsetsInsetRect(self.photosView.frame, (UIEdgeInsets){ 0, -20, -42, -20 });
	
	self.contentTextView.backgroundColor = nil;
	self.contentTextView.opaque = NO;
	self.contentTextView.contentInset = (UIEdgeInsets){ 10, 0, 0, 0 };
	self.contentTextView.bounces = YES;
	self.contentTextView.alwaysBounceVertical = YES;
	
	if ([[UIDevice currentDevice].model rangeOfString:@"Simulator"].location != NSNotFound)
		self.contentTextView.autocorrectionType = UITextAutocorrectionTypeNo;

	IRConcaveView *contentTextBackgroundView = [[[IRConcaveView alloc] initWithFrame:self.contentTextView.frame] autorelease];
	contentTextBackgroundView.autoresizingMask = self.contentTextView.autoresizingMask;
	contentTextBackgroundView.innerShadow = nil;
	contentTextBackgroundView.frame = UIEdgeInsetsInsetRect(contentTextBackgroundView.frame, (UIEdgeInsets){ -10, -20, -20, -20 });
	contentTextBackgroundView.userInteractionEnabled = NO;
	contentTextBackgroundView.backgroundColor = [UIColor colorWithWhite:0.97f alpha:1];
	[self.view insertSubview:contentTextBackgroundView atIndex:0];
		
}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];

	if (![[self.contentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length])
		[self.contentTextView becomeFirstResponder];

}





- (void) scrollViewDidScroll:(UIScrollView *)scrollView {

	if (scrollView != self.photosView)
		return;
	
	self.photosView.contentOffset = (CGPoint){
		self.photosView.contentOffset.x,
		0
	};

}

- (CGSize) portraitGridCellSizeForGridView: (AQGridView *) gridView {

	return (CGSize){ 144, 144 - 1 };

}

- (NSUInteger) numberOfItemsInGridView:(AQGridView *)gridView {

	return [self.article.fileOrder count];

}

- (AQGridViewCell *) gridView:(AQGridView *)gridView cellForItemAtIndex:(NSUInteger)index {

	static NSString * const identifier = @"photoCell";
	
	WACompositionViewPhotoCell *cell = (WACompositionViewPhotoCell *)[gridView dequeueReusableCellWithIdentifier:identifier];
	WAFile *representedFile = (WAFile *)[[self.article.files objectsPassingTest: ^ (WAFile *aFile, BOOL *stop) {
		return [[[aFile objectID] URIRepresentation] isEqual:[self.article.fileOrder objectAtIndex:index]];
	}] anyObject];
	
	if (!cell) {
	
		cell = [WACompositionViewPhotoCell cellRepresentingFile:representedFile reuseIdentifier:identifier];
		cell.frame = (CGRect){
			CGPointZero,
			[self portraitGridCellSizeForGridView:gridView]
		};
				
	}
		
	cell.image = [UIImage imageWithContentsOfFile:representedFile.resourceFilePath];

	cell.onRemove = ^ {	
		dispatch_async(dispatch_get_main_queue(), ^ {
			[representedFile.article removeFilesObject:representedFile];
		});
	};
	
	return cell;

}

- (void) handleCurrentArticleFilesChangedFrom:(id)fromValue to:(id)toValue changeKind:(NSString *)changeKind {

	NSLog(@"did change from %@ to %@ with kind %@", fromValue, toValue, changeKind);
	
	//	The idea is to animate removals and insertions using AQGridView’s own animation if possible

	dispatch_async(dispatch_get_main_queue(), ^ {
	
		if (![self isViewLoaded])
			return;
			
		@try {
		
			self.noPhotoReminderView.hidden = ([self.article.fileOrder count] > 0);
		
		} @catch (NSException *e) {
		
			self.noPhotoReminderView.hidden = YES;
		
			if (![e.name isEqualToString:NSObjectInaccessibleException])
				@throw e;
			
    } @finally {
		
			dispatch_async(dispatch_get_main_queue(), ^ {
		
				[self.photosView reloadData];
				
				UIEdgeInsets insets = [objc_getAssociatedObject(self.photosView, @"defaultInsets") UIEdgeInsetsValue];
				CGFloat addedPadding = roundf(0.5f * MAX(0, CGRectGetWidth(self.photosView.frame) - insets.left - insets.right - self.photosView.contentSize.width));
				insets.left += addedPadding;
				
				self.photosView.contentInset = insets;
				
				CGRect cellRect = [self.photosView rectForItemAtIndex:(self.photosView.numberOfItems - 1)];
				cellRect.size = [self portraitGridCellSizeForGridView:self.photosView];
				
				[self.photosView scrollRectToVisible:cellRect animated:YES];
			
			});
		
		}
		
	});

}





//	Deleting all the changed stuff and saving is like throwing all the stuff away
//	In that sense just don’t do anything.

- (void) handleDone:(UIBarButtonItem *)sender {

	//	TBD save a draft
	
	[self dismissModalViewControllerAnimated:YES];

}	

- (void) handleCancel:(UIBarButtonItem *)sender {

	[self dismissModalViewControllerAnimated:YES];

}

- (IBAction) handleCameraItemTap:(UIButton *)sender {
	
	__block __typeof__(self) nrSelf = self;
	
	NSMutableArray *availableActions = [NSMutableArray arrayWithObject:[IRAction actionWithTitle:@"Photo Library" block: ^ {
		
		nrSelf.imagePickerPopover = nil;
		[nrSelf.imagePickerPopover presentPopoverFromRect:sender.bounds inView:sender permittedArrowDirections:UIPopoverArrowDirectionLeft|UIPopoverArrowDirectionRight animated:YES];
		
	}]];
	
	if ([IRImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
	
		[availableActions addObject:[IRAction actionWithTitle:@"Take Photo" block: ^ {
			
			[nrSelf presentModalViewController:[IRImagePickerController cameraImageCapturePickerWithCompletionBlock:^(NSURL *selectedAssetURI, ALAsset *representedAsset) {
				[nrSelf handleIncomingSelectedAssetURI:selectedAssetURI representedAsset:representedAsset];
			}] animated:YES];
			
		}]];
		
	}
	
	if ([availableActions count] == 1) {
		
		//	With only one action we don’t even need to show the action sheet
		
		dispatch_async(dispatch_get_main_queue(), ^ {
			[(IRAction *)[availableActions objectAtIndex:0] invoke];
		});
		
	} else {
	
		[(IRActionSheet *)[[IRActionSheetController actionSheetControllerWithTitle:nil cancelAction:nil destructiveAction:nil otherActions:availableActions] singleUseActionSheet] showFromRect:sender.bounds inView:sender animated:YES];
		
	}
	
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
	
	if (selectedAssetURI || representedAsset) {

		NSURL *finalFileURL = nil;
		
		if (selectedAssetURI)
			finalFileURL = [[WADataStore defaultStore] persistentFileURLForFileAtURL:selectedAssetURI];
		
		if (!finalFileURL)
		if (!selectedAssetURI && representedAsset)
			finalFileURL = [[WADataStore defaultStore] persistentFileURLForData:UIImagePNGRepresentation([UIImage imageWithCGImage:[[representedAsset defaultRepresentation] fullResolutionImage]])];
		
		WAFile *stitchedFile = (WAFile *)[WAFile objectInsertingIntoContext:self.managedObjectContext withRemoteDictionary:[NSDictionary dictionary]];
		stitchedFile.resourceType = (NSString *)kUTTypeImage;
		stitchedFile.resourceURL = [finalFileURL absoluteString];
		stitchedFile.resourceFilePath = [finalFileURL path];
		stitchedFile.article = self.article;
		
	}
	
	[self.modalViewController dismissModalViewControllerAnimated:YES];
	
	if ([imagePickerPopover isPopoverVisible])
		[imagePickerPopover dismissPopoverAnimated:YES];
	
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	return YES;
	
}

@end
