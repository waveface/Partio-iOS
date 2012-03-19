//
//  WAComposeCommentViewControllerPhone.m
//  wammer-iOS
//
//  Created by jamie on 9/1/11.
//  Copyright (c) 2011 Waveface Inc. All rights reserved.
//

#import "WADefines.h"

#import "WAComposeCommentViewControllerPhone.h"
#import "WARemoteInterface.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

@interface WAComposeCommentViewControllerPhone ()

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) WAArticle *post;
@property (nonatomic, copy) void (^completionBlock)(NSURL *returnedURI);

@end

@implementation WAComposeCommentViewControllerPhone
@synthesize managedObjectContext,post;
@synthesize contentTextView, completionBlock;

+ (WAComposeCommentViewControllerPhone *)controllerWithPost:(NSURL *)aPostURLOrNil completion:(void (^)(NSURL *))aBlock
{
  WAComposeCommentViewControllerPhone *returnedController = [[self alloc] init];
  returnedController.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
  returnedController.post = (WAArticle *)[returnedController.managedObjectContext irManagedObjectForURI:aPostURLOrNil];
  
  if (!returnedController.post) {
    returnedController.post = [WAArticle objectInsertingIntoContext:returnedController.managedObjectContext withRemoteDictionary:[NSDictionary dictionary]];
    returnedController.post.draft = [NSNumber numberWithBool:YES];                           
  }
  returnedController.completionBlock = aBlock;
  
  return returnedController;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleDone:)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
  }
  return self;
}

- (void) handleManagedObjectContextDidSave:(NSNotification *)aNotification {
  
	NSManagedObjectContext *savedContext = (NSManagedObjectContext *)[aNotification object];
	
	if (savedContext == self.managedObjectContext)
		return;
	
	dispatch_async(dispatch_get_main_queue(), ^ {
    
		[self.managedObjectContext mergeChangesFromContextDidSaveNotification:aNotification];
    
	});
  
}

- (void)didReceiveMemoryWarning
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}

- (void) handleDone:(UIBarButtonItem *)sender {
  
  WAArticle *currentArticle = self.post;

	[[WADataStore defaultStore] addComment:self.contentTextView.text onArticle:[[currentArticle objectID] URIRepresentation] onSuccess:nil onFailure:nil];
	[self.navigationController popViewControllerAnimated:YES];
  
}	

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  self.title = @"Comment";
  // TODO change back button to BACK
  self.contentTextView.text = @"";
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

@end
