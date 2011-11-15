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
  WAComposeCommentViewControllerPhone *returnedController = [[[self alloc] init] autorelease];
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
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleDone:)] autorelease];
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
  
	//	Deleting all the changed stuff and saving is like throwing all the stuff away
	//	In that sense just don’t do anything.
  
	//	TBD save a draft
	
//	NSError *savingError = nil;
//	if (![self.managedObjectContext save:&savingError])
//		NSLog(@"Error saving: %@", savingError);
//	
//	if (self.completionBlock)
//		self.completionBlock([[self.post objectID] URIRepresentation]);
//	
  
  WAArticle *currentArticle = self.post;
  NSString *currentArticleIdentifier = currentArticle.identifier;
	//	NSString *currentUserIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:kWALastAuthenticatedUserIdentifier];
	
	WARemoteInterface *ri = [WARemoteInterface sharedInterface];

  [ri createCommentForPost:currentArticleIdentifier inGroup:ri.primaryGroupIdentifier withContentText:self.contentTextView.text onSuccess:^(NSDictionary *createdCommentRep) {
		
		NSManagedObjectContext *disposableContext = [[WADataStore defaultStore] disposableMOC];
		disposableContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
		
		NSMutableDictionary *mutatedCommentRep = [[createdCommentRep mutableCopy] autorelease];
		
		if ([createdCommentRep objectForKey:@"creator_id"]) {
			[mutatedCommentRep setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                    [createdCommentRep objectForKey:@"creator_id"], @"id",
                                    nil] forKey:@"owner"];
		}
		
		if ([createdCommentRep objectForKey:@"post_id"]) {
			[mutatedCommentRep setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                    [createdCommentRep objectForKey:@"post_id"], @"id",
                                    nil] forKey:@"article"];
		}
		
		NSArray *insertedComments = [WAComment insertOrUpdateObjectsUsingContext:disposableContext 
                                                          withRemoteResponse:[NSArray arrayWithObjects: mutatedCommentRep, nil] 
                                                                usingMapping:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                              @"WAFile", @"files",
                                                                              @"WAArticle", @"article",
                                                                              @"WAUser", @"owner",
                                                                              nil] options:0];
		
		for (WAComment *aComment in insertedComments)
			if (!aComment.timestamp)
				aComment.timestamp = [NSDate date];
		
		NSError *savingError = nil;
		if (![disposableContext save:&savingError])
			NSLog(@"Error saving: %@", savingError);
 				
	} onFailure:^(NSError *error) {
		
		NSLog(@"Error: %@", error);
		
	}];
	
  
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

- (void)dealloc {
  [contentTextView release];
  [super dealloc];
}
@end
