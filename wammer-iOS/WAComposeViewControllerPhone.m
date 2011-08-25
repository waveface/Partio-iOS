//
//  WAComposeViewControllerPhone.m
//  wammer-iOS
//
//  Created by jamie on 8/11/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAComposeViewControllerPhone.h"
#import "WADataStore.h"
@interface WAComposeViewControllerPhone ()

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) WAArticle *post;
@property (nonatomic, copy) void (^completionBlock)(NSURL *returnedURI);

@end

@implementation WAComposeViewControllerPhone
@synthesize managedObjectContext, post;
@synthesize contentTextView;
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
    if (self) {
        self.title = @"Compose";
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(handleCancel:)] autorelease];
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleDone:)] autorelease];
    }
    return self;
}


- (void) setPost:(WAArticle *)newPost {
    
	__block __typeof__(self) nrSelf = self;
    
	[self willChangeValueForKey:@"article"];
	
	[post irRemoveObserverBlocksForKeyPath:@"files"];	
//	[newPost irAddObserverBlock:^(id inOldValue, id inNewValue, NSString *changeKind) {
//		[nrSelf handleCurrentArticleFilesChangedFrom:inOldValue to:inNewValue changeKind:changeKind];
//	} forKeyPath:@"fileOrder" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];	
//	
	[post release];
	post = [newPost retain];
	
	[self didChangeValueForKey:@"article"];
}
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


//	Deleting all the changed stuff and saving is like throwing all the stuff away
//	In that sense just don’t do anything.

- (void) handleDone:(UIBarButtonItem *)sender {
    
	//	TBD save a draft
	self.post.text = self.contentTextView.text;
	
	NSError *savingError = nil;
	if (![self.managedObjectContext save:&savingError])
		NSLog(@"Error saving: %@", savingError);
	
	if (self.completionBlock)
		self.completionBlock([[self.post objectID] URIRepresentation]);
	
	[self.navigationController popViewControllerAnimated:YES];
    
}	

- (void) handleCancel:(UIBarButtonItem *)sender {
    
	[self.navigationController popViewControllerAnimated:YES];
    
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
    [self setContentTextView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [contentTextView release];
    [super dealloc];
}

@end
