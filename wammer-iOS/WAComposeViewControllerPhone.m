//
//  WAComposeViewControllerPhone.m
//  wammer-iOS
//
//  Created by jamie on 8/11/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "IRImagePickerController.h"

#import "WAComposeViewControllerPhone.h"
#import "WADataStore.h"
#import "WAAttachedMediaListViewController.h"


@interface WAComposeViewControllerPhone ()

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) WAArticle *post;
@property (nonatomic, copy) void (^completionBlock)(NSURL *returnedURI);

- (void) handleIncomingSelectedAssetURI:(NSURL *)selectedAssetURI representedAsset:(ALAsset *)representedAsset;

@end

@implementation WAComposeViewControllerPhone
@synthesize managedObjectContext, post;
@synthesize contentTextView;
@synthesize contentContainerView;
@synthesize attachmentsListViewControllerHeaderView;
@synthesize completionBlock;

+ (WAComposeViewControllerPhone *)controllerWithPost:(NSURL *)aPostURLOrNil completion:(void (^)(NSURL *))aBlock
{
    WAComposeViewControllerPhone *returnedController = [[[self alloc] init] autorelease];
    returnedController.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
    returnedController.post = (WAArticle *)[returnedController.managedObjectContext irManagedObjectForURI:aPostURLOrNil];
    
    if (!returnedController.post) {
        returnedController.post = [WAArticle objectInsertingIntoContext:returnedController.managedObjectContext withRemoteDictionary:[NSDictionary dictionary]];
        returnedController.post.draft = [NSNumber numberWithBool:YES];                           
    }
    returnedController.completionBlock = aBlock;
    
    return returnedController;
}

- (id)init
{
    return [self initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (!self)
		return nil;
		
	self.title = @"Compose";
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(handleCancel:)] autorelease];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStylePlain target:self action:@selector(handleDone:)] autorelease];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardNotification:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardNotification:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];

	return self;
}


- (void) setPost:(WAArticle *)newPost {
    
	//	__block __typeof__(self) nrSelf = self;
    
	[self willChangeValueForKey:@"post"];
	
	[post irRemoveObserverBlocksForKeyPath:@"files"];	
	[post release];
	post = [newPost retain];
		
	[self didChangeValueForKey:@"post"];
	
}

- (void) handleManagedObjectContextDidSave:(NSNotification *)aNotification {

	NSManagedObjectContext *savedContext = (NSManagedObjectContext *)[aNotification object];
	
	if (savedContext == self.managedObjectContext)
		return;
	
	if ([NSThread isMainThread])
		[self retain];
	else
		dispatch_sync(dispatch_get_main_queue(), ^ { [self retain]; });
	
	dispatch_async(dispatch_get_main_queue(), ^ {
	
		[self.managedObjectContext mergeChangesFromContextDidSaveNotification:aNotification];
		[self.managedObjectContext refreshObject:self.post mergeChanges:YES];
		
		if ([self isViewLoaded]) {
		
			//	Refresh view
		
		}
			
		[self autorelease];
	
	});

}

- (IBAction) handleCameraItemTap:(id)sender {

	__block WAAttachedMediaListViewController *controller = nil;
	__block __typeof__(self) nrSelf = self;
	
//	[self.post.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:self.post] error:nil];
	NSLog(@"self.post %@", self.post);
	
	if ([self.post.objectID isTemporaryID]) {
		NSError *permanentIDObtainingError = nil;
		if (![self.post.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:self.post] error:&permanentIDObtainingError])
			NSLog(@"Error obtaining permanent ID: %@", permanentIDObtainingError);
	}
	
	NSLog(@"post = %@", self.post);

  controller = [WAAttachedMediaListViewController controllerWithArticleURI:[[self.post objectID] URIRepresentation] completion: ^ (NSURL *objectURI) {
	
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
		[nrSelf.navigationController popViewControllerAnimated:YES];
		
	}];
	
	controller.headerView = self.attachmentsListViewControllerHeaderView;
	
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
  [self.navigationController pushViewController:controller animated:YES];
}

- (void) handleAttachmentAddFromCameraItemTap:(id)sender {

	if (![IRImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		return;
		
	__block IRImagePickerController *imagePickerController = [IRImagePickerController cameraCapturePickerWithCompletionBlock:^(NSURL *selectedAssetURI, ALAsset *representedAsset) {
	
		[self handleIncomingSelectedAssetURI:selectedAssetURI representedAsset:representedAsset];
		[imagePickerController dismissModalViewControllerAnimated:YES];
		
	}];
	
	[imagePickerController.view addSubview:((^ {
		UIView *decorativeView = [[[UIView alloc] initWithFrame:(CGRect){ 0, 0, 480, 20 }] autorelease];
		decorativeView.backgroundColor = [UIColor blackColor];
		return decorativeView;
	})())];

	[(self.modalViewController ? self.modalViewController : self) presentModalViewController:imagePickerController animated:YES];

}

- (void) handleAttachmentAddFromPhotosLibraryItemTap:(id)sender {

	if (![IRImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
		return;
	
	__block IRImagePickerController *imagePickerController = [IRImagePickerController photoLibraryPickerWithCompletionBlock:^(NSURL *selectedAssetURI, ALAsset *representedAsset) {
	
		[self handleIncomingSelectedAssetURI:selectedAssetURI representedAsset:representedAsset];
		[imagePickerController dismissModalViewControllerAnimated:YES];
		
	}];
	
	[imagePickerController.view addSubview:((^ {
		UIView *decorativeView = [[[UIView alloc] initWithFrame:(CGRect){ 0, 0, 480, 20 }] autorelease];
		decorativeView.backgroundColor = [UIColor blackColor];
		return decorativeView;
	})())];
	
	[(self.modalViewController ? self.modalViewController : self) presentModalViewController:imagePickerController animated:YES];

}


- (void) handleDone:(UIBarButtonItem *)sender {
    
	//	Deleting all the changed stuff and saving is like throwing all the stuff away
	//	In that sense just don’t do anything.

	//	TBD save a draft
	self.post.text = self.contentTextView.text;
	
	NSError *savingError = nil;
	if (![self.managedObjectContext save:&savingError])
		NSLog(@"Error saving: %@", savingError);
	
	if (self.completionBlock)
		self.completionBlock([[self.post objectID] URIRepresentation]);
	
	[self.parentViewController dismissModalViewControllerAnimated:YES];
    
}	

- (void) handleCancel:(UIBarButtonItem *)sender {
    
	[self.navigationController dismissModalViewControllerAnimated:YES];
    
}





- (void) handleKeyboardNotification:(NSNotification *)aNotification {

	NSDictionary *userInfo = [aNotification userInfo];
	CGRect globalFinalKeyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect keyboardRectInView = [self.view.window convertRect:globalFinalKeyboardRect toView:self.view];
	CGRect usableRect = CGRectNull, tempRect = CGRectNull;
	CGRectDivide(self.view.bounds, &usableRect, &tempRect, CGRectGetMinY(keyboardRectInView), CGRectMinYEdge);
	
	self.contentContainerView.frame = usableRect;

}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.contentTextView.text = self.post.text;
    [self.contentTextView becomeFirstResponder];
		
}

- (void)viewDidUnload
{

		self.contentTextView = nil;
		self.contentContainerView = nil;
		self.attachmentsListViewControllerHeaderView = nil;
    [super viewDidUnload];
}

- (void) viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[contentTextView release];
	[contentContainerView release];
	[attachmentsListViewControllerHeaderView release];
	[super dealloc];
}





- (void) handleIncomingSelectedAssetURI:(NSURL *)selectedAssetURI representedAsset:(ALAsset *)representedAsset {
	
	if (!selectedAssetURI)
	if (!representedAsset)
		return;

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
	stitchedFile.article = self.post;
	
	NSError *savingError = nil;
	if (![self.managedObjectContext save:&savingError])
		NSLog(@"Error saving: %@", savingError);
	
}

@end
