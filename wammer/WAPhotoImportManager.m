//
//  WAPhotoImportManager.m
//  wammer
//
//  Created by kchiu on 12/9/11.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAPhotoImportManager.h"
#import "WADataStore.h"
#import "WAArticle.h"
#import "WAAssetsLibraryManager.h"
#import "WAFile+ThumbnailMaker.h"
#import <AssetsLibrary+IRAdditions.h>
#import "WAFileExif.h"
#import "GAI.h"
#import "WADefines.h"
#import "WAFileExif+WAAdditions.h"

@interface WAPhotoImportManager ()

@property (nonatomic, readwrite) BOOL preprocessing;
@property (nonatomic, readwrite) NSUInteger totalOperationCount;
@property (nonatomic, readwrite, strong) NSOperationQueue *operationQueue;
@property (nonatomic, readwrite, strong) NSDate *lastOperationTimestamp;

@end

@implementation WAPhotoImportManager

- (id)init {

	self = [super init];
	if (self) {
		self.operationQueue = [[NSOperationQueue alloc] init];
		self.operationQueue.maxConcurrentOperationCount = 1;

		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		self.enabled = [defaults boolForKey:kWAPhotoImportEnabled];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUserDefaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
	}
	return self;

}

- (void)handleUserDefaultsChanged:(NSNotification *)notification {

	NSUserDefaults *defaults = [notification object];
	if (self.enabled != [defaults boolForKey:kWAPhotoImportEnabled]) {
		self.enabled = [defaults boolForKey:kWAPhotoImportEnabled];
		if (self.enabled) {
			[self createPhotoImportArticlesWithCompletionBlock:^{
				NSLog(@"All photo import operations are enqueued");
			}];
		} else {
			[self.operationQueue cancelAllOperations];
		}
	}

}

- (void)createPhotoImportArticlesWithCompletionBlock:(void(^)(void))aCallbackBlock {

	__weak WAPhotoImportManager *wSelf = self;
	if ([NSThread isMainThread]) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[wSelf createPhotoImportArticlesWithCompletionBlock:aCallbackBlock];
		});
		return;
	}

	self.preprocessing = YES;

	NSDate *importTime = [NSDate date];
	NSDate *sinceDate = self.lastOperationTimestamp;
	if (!sinceDate) {
		WADataStore *ds = [WADataStore defaultStore];
		sinceDate = [[ds fetchLatestLocalImportedArticleUsingContext:[ds disposableMOC]] creationDate];
	}

	[[WAAssetsLibraryManager defaultManager] enumerateSavedPhotosSince:sinceDate onProgess:^(NSArray *assets) {

		if (![assets count]) {
			return;
		}

		wSelf.totalOperationCount += [assets count];
		wSelf.lastOperationTimestamp = [[assets lastObject] valueForProperty:ALAssetPropertyDate];

		__block NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{

			if ([operation isCancelled]) {
				NSLog(@"A photo import operation was canceled");
				return;
			}

			NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
			WAArticle *article = [WAArticle objectInsertingIntoContext:context withRemoteDictionary:@{}];
			[assets enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				
				@autoreleasepool {
					
					WAFile *file = (WAFile *)[WAFile objectInsertingIntoContext:context withRemoteDictionary:@{}];
					CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
					if (theUUID)
						file.identifier = [((__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, theUUID)) lowercaseString];
					CFRelease(theUUID);
					file.dirty = (id)kCFBooleanTrue;
					
					[[article mutableOrderedSetValueForKey:@"files"] addObject:file];
					
					ALAsset *asset = (ALAsset *)obj;
					
					UIImage *extraSmallThumbnailImage = [UIImage imageWithCGImage:[asset thumbnail]];
					file.extraSmallThumbnailFilePath = [[[WADataStore defaultStore] persistentFileURLForData:UIImageJPEGRepresentation(extraSmallThumbnailImage, 0.85f) extension:@"jpeg"] path];
					
					file.assetURL = [[[asset defaultRepresentation] url] absoluteString];
					file.resourceType = (NSString *)kUTTypeImage;
					file.timestamp = [asset valueForProperty:ALAssetPropertyDate];
					file.importTime = importTime;
					
					WAFileExif *exif = (WAFileExif *)[WAFileExif objectInsertingIntoContext:context withRemoteDictionary:@{}];
					NSDictionary *metadata = [[asset defaultRepresentation] metadata];
					[exif initWithExif:metadata[@"{Exif}"] tiff:metadata[@"{TIFF}"] gps:metadata[@"{GPS}"]];

					file.exif = exif;
					
					if (!article.creationDate) {
						article.creationDate = file.timestamp;
					} else {
						if ([file.timestamp compare:article.creationDate] == NSOrderedDescending) {
							article.creationDate = file.timestamp;
						}
					}
					
				}
				
			}];
			
			article.import = [NSNumber numberWithInt:WAImportTypeFromLocal];
			article.draft = (id)kCFBooleanFalse;
			CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
			if (theUUID)
				article.identifier = [((__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, theUUID)) lowercaseString];
			CFRelease(theUUID);
			article.dirty = (id)kCFBooleanTrue;
			article.creationDeviceName = [UIDevice currentDevice].name;
			
			NSError *savingError = nil;
			if ([context save:&savingError]) {
				[[GAI sharedInstance].defaultTracker trackEventWithCategory:@"CreatePost"
																												 withAction:@"CameraRoll"
																													withLabel:@"Photos"
																													withValue:@([article.files count])];
			} else {
				NSLog(@"Error saving: %s %@", __PRETTY_FUNCTION__, savingError);
			}
			
			return;

		}];
		
		[wSelf.operationQueue addOperation:operation];

	} onComplete:^{
		
		wSelf.preprocessing = NO;
		aCallbackBlock();
		
	} onFailure:^(NSError *error) {
		
		NSLog(@"Unable to enumerate saved photos: %s %@", __PRETTY_FUNCTION__, error);
		aCallbackBlock();

	}];
	
}

- (void)dealloc {

	[self.operationQueue cancelAllOperations];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (void)waitUntilFinished {

	[self.operationQueue waitUntilAllOperationsAreFinished];

}

@end
