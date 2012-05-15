//
//  WAAttachedMediaListViewController.m
//  wammer-iOS
//
//  Created by Evadne Wu on 8/26/11.
//  Copyright 2011 Waveface Inc. All rights reserved.
//

#import "WAAttachedMediaListViewController.h"
#import "IRView.h"
#import "WADataStore.h"

#import "QuartzCore+IRAdditions.h"


@interface WAAttachedMediaListViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, readwrite, copy) void(^callback)(void);
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) WAArticle *article;

@property (nonatomic, readwrite, retain) id articleFilesObservingsHelper;

@property (nonatomic, readwrite, assign, getter=isUndergoingProgrammaticEntityMutation, setter=setUndergoingProgrammaticEntityMutation:) BOOL undergoingProgrammaticEntityMutation;

@end


@implementation WAAttachedMediaListViewController
@synthesize callback, tableView;
@synthesize managedObjectContext, article;
@synthesize articleFilesObservingsHelper;
@synthesize onViewDidLoad;
@synthesize undergoingProgrammaticEntityMutation;

- (id) init {

	return [self initWithArticleURI:nil completion:nil];

}

- (WAAttachedMediaListViewController *) initWithArticleURI:(NSURL *)anArticleURI completion:(void (^)(void))aBlock {
	
	return [self initWithArticleURI:anArticleURI usingContext:nil completion:aBlock];

}

- (WAAttachedMediaListViewController *) initWithArticleURI:(NSURL *)anArticleURI usingContext:(NSManagedObjectContext *)aContext completion:(void (^)(void))aBlock {

	self = [super init];
	if (!self)
		return nil;
	
	__weak WAAttachedMediaListViewController *wSelf = self;
	
	self.navigationItem.leftBarButtonItem = [IRBarButtonItem itemWithSystemItem:UIBarButtonSystemItemDone wiredAction:^(IRBarButtonItem *senderItem) {
		
		if (wSelf.callback)
			wSelf.callback();
		
	}];
	
	self.callback = aBlock;
	self.title = @"Attachments";
	
	if (aContext) {
		self.managedObjectContext = aContext;
	} else {
		self.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
		self.managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	}
	
	self.article = (WAArticle *)[self.managedObjectContext irManagedObjectForURI:anArticleURI];
	
	self.articleFilesObservingsHelper =  [self.article irAddObserverBlock: ^ (id inOldValue, id inNewValue, NSKeyValueChange changeKind) {
	
		if (![wSelf isViewLoaded])
			return;
		
		if ([wSelf isUndergoingProgrammaticEntityMutation])
			return;
		
		[wSelf.tableView reloadData];
		
		// Fixme: Use NSFRC
		// Fixme: Also remove dupe KVO invocations
		
	} forKeyPath:@"files" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
	
	return self;

}

- (void) dealloc {

	[article irRemoveObservingsHelper:self.articleFilesObservingsHelper];
	
}

- (void) loadView {

	self.view = [[IRView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.rootViewController.view.bounds];
	
	tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.rowHeight = 76.0f; // plus 1 to get UIImageView in right size
	self.navigationController.navigationBar.tintColor = [UIColor darkGrayColor];
	[self.view addSubview:self.tableView];
	
}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	if (self.onViewDidLoad)
		self.onViewDidLoad();
	
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {

	return 1;

}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	return [self.article.files count];

}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

	switch (editingStyle) {
	case UITableViewCellEditingStyleDelete: {
		
		NSUInteger deletedFileIndex = indexPath.row;
		NSURL *deletedFileURI = [self.article.files objectAtIndex:deletedFileIndex];
		WAFile *removedFile = (WAFile *)[self.managedObjectContext irManagedObjectForURI:deletedFileURI];
		
		[self.tableView beginUpdates];
		
		self.undergoingProgrammaticEntityMutation = YES;
		
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
		[self.article removeFilesObject:removedFile];

		self.undergoingProgrammaticEntityMutation = NO;
		
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
	
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
		cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	WAFile *representedFile = [self.article.files objectAtIndex:indexPath.row];
	UIImage *resourceImage = representedFile.resourceImage;
	
	cell.imageView.contentMode = UIViewContentModeScaleAspectFill;

	if (resourceImage) {
  
		cell.imageView.image = representedFile.thumbnail;
		
		cell.textLabel.text = [NSString stringWithFormat:@"%1.0f × %1.0f", 
			resourceImage.size.width,
			resourceImage.size.height
		];
  
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:representedFile.resourceFilePath error:nil];
		long fileSize = [[fileAttributes objectForKey:NSFileSize] longValue];
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0fK", (float)fileSize/(1024.0)];
	
	} else {
	
		//	TBD: When the Data Store stores metadata, use stored metadat in place
		
		cell.imageView.image = representedFile.thumbnailImage;
		cell.textLabel.text = @"";
		cell.detailTextLabel.text = @"File not loaded";
	
	}
	
	return cell;

}

- (BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	
	return YES;
	
}

- (void) tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{

	self.undergoingProgrammaticEntityMutation = YES;

	NSMutableOrderedSet *newFiles = [self.article.files mutableCopy];
	[newFiles moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:[sourceIndexPath row]] toIndex:[destinationIndexPath row]];
	
	self.article.files = newFiles;
	
	self.undergoingProgrammaticEntityMutation = NO;
	
}
@end
