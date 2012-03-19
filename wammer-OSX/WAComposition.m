//
//  WAComposition.m
//  wammer
//
//  Created by Evadne Wu on 12/18/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAComposition.h"
#import "WARemoteInterface.h"
#import "WADataStore.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"
#import "WAProgressIndicatorWindow.h"

@interface WAComposition ()
@property (nonatomic, readwrite, retain) WAArticle *article;
@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;
@end

@implementation WAComposition
@synthesize managedObjectContext;
@synthesize article;
@synthesize textView;
@synthesize spinner;
@synthesize collectionView;

- (id) init {
	
	self = [super init];
	
	if (!self)
		return nil;
	
	self.article = [WAArticle objectInsertingIntoContext:self.managedObjectContext withRemoteDictionary:nil];
	self.article.draft = (NSNumber *)kCFBooleanTrue;
	
	return self;
	
}

- (NSManagedObjectContext *) managedObjectContext {

	if (managedObjectContext)
		return managedObjectContext;
	
	managedObjectContext = [[[WADataStore defaultStore] disposableMOC] retain];
	managedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
	return managedObjectContext;

}

- (NSString *) windowNibName {
	
	return @"WAComposition";
	
}

- (void) windowControllerDidLoadNib:(NSWindowController *)aController {
	
	[super windowControllerDidLoadNib:aController];
	
	//	?
	
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return YES;
}

+ (BOOL) autosavesInPlace {
	return NO;
}

- (IBAction)handleSend:(id)sender {

	NSLog(@"Should Send");
	
	NSTextStorage *textStorage = [self.textView textStorage];
	NSRange wantedRange = (NSRange){ 0, [textStorage length] };
	NSDictionary *wantedAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
		NSHTMLTextDocumentType, NSDocumentTypeDocumentAttribute,
		[NSArray arrayWithObjects:@"doctype", @"html", @"head", @"body", @"xml", nil], NSExcludedElementsDocumentAttribute,
	nil];
	
	NSData *htmlData = [textStorage dataFromRange:wantedRange documentAttributes:wantedAttrs error:nil];
	NSLog(@"htmlData %@", htmlData);
	
	self.article.text = [textStorage string];
	
	WAProgressIndicatorWindow *busyWindow = [[WAProgressIndicatorWindow fromNib] retain];
	[NSApp beginSheet:busyWindow modalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:nil contextInfo:nil];
	
	[self.managedObjectContext save:nil];
		
	NSURL *articleURI = [[self.article objectID] URIRepresentation];
	[[WADataStore defaultStore] uploadArticle:articleURI onSuccess: ^ {
	
		NSParameterAssert([NSThread isMainThread]);
	
		self.article.draft = (NSNumber *)kCFBooleanFalse;
		
		NSError *savingError = nil;
		if (![self.managedObjectContext save:&savingError])
			NSLog(@"Error saving: %@", savingError);
		
		[NSApp endSheet:busyWindow];
		
		[self close];
	
	} onFailure: ^ (NSError *error) {
	
		[NSApp endSheet:busyWindow];
	
	}];
	
}

@end
