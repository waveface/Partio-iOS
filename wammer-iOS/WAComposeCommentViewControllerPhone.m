//
//  WAComposeCommentViewControllerPhone.m
//  wammer-iOS
//
//  Created by jamie on 9/1/11.
//  Copyright (c) 2011 Waveface Inc. All rights reserved.
//

#import "WAComposeCommentViewControllerPhone.h"
#import "WADataStore.h"

@interface WAComposeCommentViewControllerPhone ()

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) WAArticle *post;
@property (nonatomic, copy) void (^completionBlock)(NSURL *returnedURI);

@end

@implementation WAComposeCommentViewControllerPhone
@synthesize managedObjectContext,post;
@synthesize contentTextView;

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
  }
  return self;
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
	NSLog(@"self.post.text = self.contentTextView.text");
	
//	NSError *savingError = nil;
//	if (![self.managedObjectContext save:&savingError])
//		NSLog(@"Error saving: %@", savingError);
//	
//	if (self.completionBlock)
//		self.completionBlock([[self.post objectID] URIRepresentation]);
//	
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
