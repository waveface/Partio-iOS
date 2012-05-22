//
//  WAPreviewInspectionViewController.m
//  wammer
//
//  Created by jamie on 2/15/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAPreviewInspectionViewController.h"
#import "WADataStore.h"
#import "WANavigationController.h"
#import "CoreData+IRAdditions.h"
#import "UIKit+IRAdditions.h"

@interface WAPreviewInspectionViewController ()

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readwrite, retain) WAPreview *preview;

@end

@implementation WAPreviewInspectionViewController
@synthesize managedObjectContext;
@synthesize deleteButton, previewBadge, preview, delegate;

+ (id) controllerWithPreview:(NSURL *)anURL {

	WAPreviewInspectionViewController *controller = [[self alloc] init];
	controller.managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	controller.preview = (WAPreview *)[controller.managedObjectContext irManagedObjectForURI:anURL];
	
	if (![controller.preview isKindOfClass:[WAPreview class]])
		return nil;
	
	return controller;

}

- (UINavigationController *) wrappingNavController {

	if (self.navigationController)
		return self.navigationController;
	
	WANavigationController *returnedNavC = [[WANavigationController alloc] initWithRootViewController:self];
	return returnedNavC;

}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (!self)
		return nil;
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleDoneTap:)];
	
	return self;
	
}

- (void) viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];
	
	if ([self.managedObjectContext isKindOfClass:[IRManagedObjectContext class]]) {
	
		//	Prepare for preview refreshes, such as image updates, if appropriate
	
		[(IRManagedObjectContext *)self.managedObjectContext irBeginMergingFromSavesAutomatically];
		[self.managedObjectContext refreshObject:self.preview mergeChanges:YES];
	
	}

}

- (void) viewWillDisappear:(BOOL)animated {

	if ([self.managedObjectContext isKindOfClass:[IRManagedObjectContext class]]) {
	
		//	Prepare for preview refreshes, such as image updates, if appropriate
	
		[(IRManagedObjectContext *)self.managedObjectContext irStopMergingFromSavesAutomatically];
	
	}

	[super viewWillDisappear:animated];

}

- (void) viewDidLoad {

	[super viewDidLoad];
	
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"lightBackground"]];
	
	deleteButton.backgroundColor = nil;
		
	deleteButton.titleLabel.shadowColor = [UIColor lightGrayColor];
	deleteButton.titleLabel.shadowOffset = (CGSize){ 0, -1 };
	
	deleteButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	deleteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	
	[deleteButton setBackgroundColor:[UIColor clearColor]];
	
	[deleteButton setBackgroundImage:[IRUIKitImage(@"UINavigationBarRemoveButton") stretchableImageWithLeftCapWidth:5 topCapHeight:12] forState:UIControlStateNormal];
	[deleteButton setBackgroundImage:[IRUIKitImage(@"UINavigationBarRemoveButtonPressed") stretchableImageWithLeftCapWidth:5 topCapHeight:0] forState:UIControlStateHighlighted];
	
	previewBadge.preview = self.preview;
	previewBadge.titleColor = [UIColor colorWithRed:198.0/255.0 green:107.0/255.0 blue:75.0/255.0 alpha:1.0];
	previewBadge.textColor = [UIColor colorWithRed:118.0/255.0 green:116.0/255.0 blue:111.0/255.0 alpha:1.0];
	
}

- (void) viewDidUnload {

	self.deleteButton = nil;
	self.previewBadge = nil;	
	
	[super viewDidUnload];

}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
	
}

- (void) setPreview:(WAPreview *)newPreview {

	NSCAssert2(![[newPreview objectID] isTemporaryID], @"%s: the incoming preview %@ is a temporary one and won’t work properly", __PRETTY_FUNCTION__, newPreview);

	if (preview == newPreview)
		return;
	
	preview = newPreview;

}

- (IBAction) handleDeleteTap:(id)sender {

	[self.delegate previewInspectionViewControllerDidRemove:self];

}

- (void) handleDoneTap:(id)sender {

	[self.delegate previewInspectionViewControllerDidFinish:self];

}

@end
