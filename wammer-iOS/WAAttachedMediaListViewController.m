//
//  WAAttachedMediaListViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/26/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "WAAttachedMediaListViewController.h"
#import "WAView.h"
#import "WADataStore.h"
#import "WATableViewCell.h"


@interface WAAttachedMediaListViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, readwrite, copy) void(^callback)(NSURL *objectURI);
@property (nonatomic, readwrite, retain) UITableView *tableView;

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) WAArticle *article;

@end


@implementation WAAttachedMediaListViewController
@synthesize callback, headerView, tableView;
@synthesize managedObjectContext, article;

+ (WAAttachedMediaListViewController *) controllerWithArticleURI:(NSURL *)anArticleURI completion:(void(^)(NSURL *objectURI))aBlock {

	return [[[self alloc] initWithArticleURI:anArticleURI completion:aBlock] autorelease];

}

- (id) init {

	return [self initWithArticleURI:nil completion:nil];

}

- (WAAttachedMediaListViewController *) initWithArticleURI:(NSURL *)anArticleURI completion:(void (^)(NSURL *))aBlock {

	self = [super init];
	if (!self)
		return nil;
	
	__block __typeof__(self) nrSelf = self;
	
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	
	self.navigationItem.rightBarButtonItem = [IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemDone wiredAction:^(IRBarButtonItem *senderItem) {
		
		if (nrSelf.callback)
			nrSelf.callback(nil);
		
	}];
	
	self.callback = aBlock;
	self.title = @"Attachments";
	
	self.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	self.managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	self.article = (WAArticle *)[self.managedObjectContext irManagedObjectForURI:anArticleURI];
	
	NSLog(@"anArticleURI %@",  anArticleURI);
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
	
	return self;

}

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[managedObjectContext release];
	[article release];

	[callback release];
	[headerView release];
	[super dealloc];

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
		[self.managedObjectContext refreshObject:self.article mergeChanges:YES];
		
		if ([self isViewLoaded]) {
			[self.tableView reloadData];
		}
			
		[self autorelease];
	
	});

}




- (void) setEditing:(BOOL)editing animated:(BOOL)animated {

	[super setEditing:editing animated:animated];
	[self.tableView setEditing:editing animated:animated];
	
	if (editing) {
		self.navigationItem.rightBarButtonItem.enabled = NO;
	} else {
		self.navigationItem.rightBarButtonItem.enabled = YES;
	}

}

- (void) loadView {

	self.view = [[[WAView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.rootViewController.view.bounds] autorelease]; // dummy size for autoresizing
	
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"WAPhotoQueueBackground"]];
	
	self.tableView = [[[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain] autorelease];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.rowHeight = 64.0f;
	[self.view addSubview:self.tableView];
	
	__block __typeof__(self) nrSelf = self;
	
	((WAView *)self.view).onLayoutSubviews = ^ {
	
		//	Handle header view conf
		
		CGFloat headerViewHeight = 0.0f;
		
		if (nrSelf.headerView) {
			[nrSelf.view addSubview:nrSelf.headerView];
			headerViewHeight = CGRectGetHeight(nrSelf.headerView.bounds);
		}
			
		nrSelf.headerView.frame = (CGRect){
			CGPointZero,
			(CGSize){
				CGRectGetWidth(nrSelf.view.bounds),
				CGRectGetHeight(nrSelf.headerView.bounds)
			}
		};
		
		nrSelf.tableView.frame = (CGRect){
			(CGPoint){
				0,
				headerViewHeight
			},
			(CGSize){
				CGRectGetWidth(nrSelf.view.bounds),
				CGRectGetHeight(nrSelf.view.bounds) - headerViewHeight
			}
		};
		
		//	Relocate table view
	
	};

}

- (void) viewDidUnload {

	self.headerView = nil;
	
	[super viewDidUnload];

}





- (void) setHeaderView:(UIView *)newHeaderView {

	if (headerView == newHeaderView)
		return;
	
	if ([self isViewLoaded])
		if ([headerView isDescendantOfView:self.view])
			[headerView removeFromSuperview];
	
	[self willChangeValueForKey:@"headerView"];
	[headerView release];
	headerView = [newHeaderView retain];
	[self didChangeValueForKey:@"headerView"];
	
	if ([self isViewLoaded])
		[self.view setNeedsLayout];

} 

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}





- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {

	return 1;

}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	NSInteger count = [self.article.fileOrder count];
	NSLog(@"count %i", count);
	return count;

}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

	switch (editingStyle) {
	case UITableViewCellEditingStyleDelete: {
		
		NSUInteger deletedFileIndex = indexPath.row;
		NSURL *deletedFileURI = [self.article.fileOrder objectAtIndex:deletedFileIndex];
		WAFile *removedFile = (WAFile *)[self.managedObjectContext irManagedObjectForURI:deletedFileURI];
		removedFile.article = nil;
		
		[self.article removeFilesObject:removedFile];

		NSError *savingError = nil;
		if (![self.managedObjectContext save:&savingError]) {
			
			id oldMergePolicy = [[self.managedObjectContext.mergePolicy retain] autorelease];
			self.managedObjectContext.mergePolicy = NSOverwriteMergePolicy; //hmph
			NSLog(@"Error saving: %@", savingError);
			
			if (![self.managedObjectContext save:&savingError])
				NSLog(@"%s failed spectacularly", __PRETTY_FUNCTION__);
			
			self.managedObjectContext.mergePolicy = oldMergePolicy;
			
		}
		
		
			
		[self.tableView beginUpdates];
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
		[self.tableView endUpdates];
		
		break;
		
	}
	case UITableViewCellEditingStyleNone: {
		break;
	};
	case UITableViewCellEditingStyleInsert: {
		break;
	}
	}

}

- (UITableViewCell *) tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *identifier = @"Identifier";
	
	WATableViewCell *cell = (WATableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:identifier];
	if (!cell) {
		
		cell = [[[WATableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
		cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.indentationWidth = 8.0f;
		
		cell.onSetEditing = ^ (WATableViewCell *self, BOOL editing, BOOL animated) {

			if (editing) {
				self.indentationLevel = 1;
			} else {
				self.indentationLevel = 0;
			}
		
		};

	}
	
	NSURL *fileURI = [self.article.fileOrder objectAtIndex:indexPath.row];
	WAFile *representedFile = (WAFile *)[[self.article.files objectsPassingTest: ^ (id obj, BOOL *stop) {
	
		BOOL objectMatches = [[[obj objectID] URIRepresentation] isEqual:fileURI];
		
		if (objectMatches)
			*stop = YES;
		
		return objectMatches;
		
	}] anyObject];
	
	UIImage *actualImage = [UIImage imageWithContentsOfFile:representedFile.resourceFilePath];
	
	cell.imageView.image = [actualImage irScaledImageWithSize:(CGSize){
		aTableView.rowHeight,
		aTableView.rowHeight
	}];
		
	cell.textLabel.text = [NSString stringWithFormat:@"%1.0f × %1.0f", actualImage.size.width, actualImage.size.height];
	cell.detailTextLabel.text = @"Detail?";
	
	return cell;

}

@end
