//
//  IPUserSelectionViewController.m
//  Instaphoto
//
//  Created by Evadne Wu on 6/22/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
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
	
	[self.managedObjectContext mergeChangesFromContextDidSaveNotification:aNotification];
	
	NSError *fetchingError = nil;
	if (![fetchedResultsController performFetch:&fetchingError])
		NSLog(@"Error (re)fetching %@", fetchingError);
	
	dispatch_async(dispatch_get_main_queue(), ^ {
	
		if ([self isViewLoaded]) {
			if ([self.tableView.indexPathsForVisibleRows count]) {
				[self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationNone];
			} else {
				[self.tableView reloadData];
			}
		}
		
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
	fetchRequest.predicate = [NSPredicate predicateWithFormat:@"self != nil"];

	fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	
	NSError *fetchingError = nil;
	if (![fetchedResultsController performFetch:&fetchingError])
		NSLog(@"Error fetching %@", fetchingError);
	
	return fetchedResultsController;

}

- (void) viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	
	[self handleRefresh];
	[self.tableView reloadData];

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

	return YES;

}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	return 2;//[[self.fetchedResultsController.sections objectAtIndex:section] numberOfObjects];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *identifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	
	if (!cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
	}
	
    if([indexPath row] == 0){
        cell.textLabel.text = @"Kitty";
        cell.imageView.image = [UIImage imageNamed:@"IPSample/IPSample_001.jpg"]; 
    }else{
        cell.textLabel.text = @"Kitten";
        cell.imageView.image = [UIImage imageNamed:@"IPSample/IPSample_002.jpg"]; 
    }
    
    return cell;
    
	WAUser *representedUser = [self.fetchedResultsController objectAtIndexPath:indexPath];

	//	NSDictionary *userObject = (NSDictionary *)[self.eligibleUsers objectAtIndex:indexPath.row];
	
	if ([representedUser.identifier isEqual:[[WADataStore defaultStore] currentUserIdentifier]]) {
	
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	
	} else {
	
		cell.accessoryType = UITableViewCellAccessoryNone;
	
	}
	
	cell.textLabel.text = representedUser.nickname;
	cell.imageView.image = representedUser.avatar;
	
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

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

	return @"Pick a user";

}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    return ;
	NSURL *userRep = [[(IRManagedObject *)[self.fetchedResultsController objectAtIndexPath:indexPath] objectID] URIRepresentation];

	dispatch_async(dispatch_get_main_queue(), ^ {
	
		if (self.completionBlock)
			self.completionBlock(userRep);
	
	});
	
}





- (void) handleRefresh {
    NSArray *retrievedUsers = [[NSArray alloc]init];
    NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
    [WAUser insertOrUpdateObjectsIntoContext:context withExistingProperty:@"identifier" matchingKeyPath:@"uid" ofRemoteDictionaries:retrievedUsers];
}

@end
