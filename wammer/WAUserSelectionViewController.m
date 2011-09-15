//
//  IPUserSelectionViewController.m
//  Instaphoto
//
//  Created by Evadne Wu on 6/22/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import "WAUserSelectionViewController.h"
#import "WADataStore.h"
#import "WAUser.h"
#import "WARemoteInterface.h"

@interface WAUserSelectionViewController ()

- (void) handleRefresh;

@property (nonatomic, readwrite, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;

@end


@implementation WAUserSelectionViewController
@synthesize eligibleUsers, completionBlock;
@synthesize fetchedResultsController, managedObjectContext;

+ (WAUserSelectionViewController *) controllerWithElectibleUsers:(NSArray *)users onSelection:(void(^)(NSURL *pickedUser))completion {

	WAUserSelectionViewController *returnedController = [[[self alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	returnedController.eligibleUsers = users ? users : [NSArray array];
	returnedController.completionBlock = completion;
	
	return returnedController;

}

- (id) initWithStyle:(UITableViewStyle)style {

	self = [super initWithStyle:style];
	if (!self) return nil;
	
	self.title = @"Welcome";
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
	
	return self;
	
}

- (void) handleManagedObjectContextDidSave:(NSNotification *)aNotification {

	NSManagedObjectContext *originContext = [aNotification object];
	
	if ((originContext == self.managedObjectContext) || ![originContext.persistentStoreCoordinator.managedObjectModel isEqual:self.managedObjectContext.persistentStoreCoordinator.managedObjectModel]) {
	
		return;
	
	}
	
	dispatch_async(dispatch_get_main_queue(), ^ {
	
		[self.managedObjectContext mergeChangesFromContextDidSaveNotification:aNotification];
		
		if (![self isViewLoaded])
			return;

		self.fetchedResultsController = nil;
		
		[self.tableView reloadData];
		
	});

}

- (void) dealloc {

	[eligibleUsers release];
	[completionBlock release];
	
	[fetchedResultsController release];
	[managedObjectContext release];
	
	[super dealloc];

}

- (NSManagedObjectContext *) managedObjectContext {

	if (managedObjectContext)
		return managedObjectContext;
		
	managedObjectContext = [[[WADataStore defaultStore] disposableMOC] retain];
	
	return managedObjectContext;

}

- (NSFetchedResultsController *) fetchedResultsController {

	if (fetchedResultsController)
		return fetchedResultsController;
	
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	fetchRequest.entity = [WAUser entityDescriptionForContext:self.managedObjectContext];
	fetchRequest.sortDescriptors = [NSArray arrayWithObjects:
		[NSSortDescriptor sortDescriptorWithKey:@"nickname" ascending:YES],
	nil];
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(self != nil) AND (nickname != nil)"];

	fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	
	NSError *fetchingError = nil;
	if (![fetchedResultsController performFetch:&fetchingError])
		NSLog(@"Error fetching %@", fetchingError);
	
	return fetchedResultsController;

}

- (void) viewDidLoad {

	[super viewDidLoad];
	[self.tableView reloadData];

}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	[self handleRefresh];

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

	return YES;

}

- (NSInteger) numberOfSectionsInTableView {

	if (!self.fetchedResultsController.fetchedObjects)
		return 0;
	
	return 1;

}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	if (!self.fetchedResultsController.fetchedObjects)
		return 0;
	
	return [[self.fetchedResultsController.sections objectAtIndex:section] numberOfObjects];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *identifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	if (!cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
		cell.layer.shouldRasterize = YES;
	}
	
	WAUser *representedUser = [self.fetchedResultsController objectAtIndexPath:indexPath];
	if (!representedUser) {
		NSLog(@"NO REPRESENTED USER");
	}
	NSParameterAssert(representedUser);
	
	NSString *currentUser = [[NSUserDefaults standardUserDefaults] stringForKey:@"WhoAmI"];
	BOOL representedUserIsCurrentUser = [representedUser.identifier isEqualToString:currentUser];
	
	cell.accessoryType = representedUserIsCurrentUser ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	cell.textLabel.text = representedUser.nickname;
	cell.imageView.image = representedUser.avatar;
	
	if (!cell.imageView.image)
		cell.imageView.image = [UIImage imageNamed:@"WADefaultUserIcon"];
	
	//	Visual: Add a rounded corner on the top left or lower left of the image
	
	if (indexPath.row == 0) {
	
		cell.imageView.layer.mask = [CAShapeLayer layer];
		cell.imageView.layer.mask.bounds = (CGRect){ 0, 0, 44, 44 };
		((CAShapeLayer *)(cell.imageView.layer.mask)).path = (CGPathRef)[UIBezierPath bezierPathWithRoundedRect:(CGRect){ 22, 22, 44, 44 } byRoundingCorners:UIRectCornerTopLeft cornerRadii:(CGSize){ 10.0f, 10.0f }].CGPath;
		
	} else if (indexPath.row == ([self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)) {
	
		cell.imageView.layer.mask = [CAShapeLayer layer];
		cell.imageView.layer.mask.bounds = (CGRect){ 0, 0, 44, 44 };
		((CAShapeLayer *)(cell.imageView.layer.mask)).path = (CGPathRef)[UIBezierPath bezierPathWithRoundedRect:(CGRect){ 22, 22, 44, 44 } byRoundingCorners:UIRectCornerBottomLeft cornerRadii:(CGSize){ 10.0f, 10.0f }].CGPath;

	} else {
	
		cell.imageView.layer.mask = nil;
	
	}
	
	
	return cell;
	
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	WAUser *changeToUser = [self.fetchedResultsController objectAtIndexPath:indexPath];
	[[NSUserDefaults standardUserDefaults] setObject:changeToUser.identifier forKey:@"WhoAmI"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	NSURL *userRep = [[(IRManagedObject *)changeToUser objectID] URIRepresentation];

	[self.tableView reloadData];
    
	dispatch_async(dispatch_get_main_queue(), ^ {
	
		if (self.completionBlock)
			self.completionBlock(userRep);
	
	});
	
}





- (void) handleRefresh {

	[[WADataStore defaultStore] updateUsersOnSuccess: ^ {
	
		//	No op, changes are merged thru notifications
	
	} onFailure:nil];

}

@end
