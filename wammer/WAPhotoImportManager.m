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

@interface WAPhotoImportManager ()

@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation WAPhotoImportManager

+ (WAPhotoImportManager *) defaultManager {
	
	static WAPhotoImportManager *returnedManager = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
		
		returnedManager = [[self alloc] init];
    
	});
	
	return returnedManager;
	
}

- (id)init {

	self = [super init];
	if (self) {
		self.finished = YES;
		self.canceled = NO;
	}
	return self;

}

- (NSManagedObjectContext *)managedObjectContext {

	if (!_managedObjectContext) {
		_managedObjectContext = [[WADataStore defaultStore] disposableMOC];
	}
	return _managedObjectContext;

}

- (WAArticle *)lastImportedArticle {

	if (!_lastImportedArticle) {
		_lastImportedArticle = [[WADataStore defaultStore] fetchLatestLocalImportedArticleUsingContext:self.managedObjectContext];
	}
	return _lastImportedArticle;

}

- (void)cancelPhotoImportWithCompletionBlock:(WAPhotoImportCallback)aCallbackBlock {

	self.canceled = YES;

	__weak WAPhotoImportManager *wSelf = self;
	[self irObserve:@"finished" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {

		BOOL isFinished = [toValue boolValue];
		if (isFinished) {
			wSelf.managedObjectContext = nil;
			wSelf.lastImportedArticle = nil;
			aCallbackBlock();
		}

	}];

}

- (void)createPhotoImportArticlesWithCompletionBlock:(WAPhotoImportCallback)aCallbackBlock {

	if (!self.finished) {
		return;
	}

	self.finished = NO;
	self.canceled = NO;

	NSDate *importTime = [NSDate date];

	NSManagedObjectContext *context = self.managedObjectContext;
	__weak WAPhotoImportManager *wSelf = self;

	[context performBlock:^{

		[[WAAssetsLibraryManager defaultManager] enumerateSavedPhotosSince:wSelf.lastImportedArticle.creationDate onProgess:^(NSArray *assets) {

			if (![assets count]) {
				return wSelf.canceled;
			}

			WAArticle *article = [WAArticle objectInsertingIntoContext:context withRemoteDictionary:[NSDictionary dictionary]];
			[assets enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

				@autoreleasepool {

					WAFile *file = (WAFile *)[WAFile objectInsertingIntoContext:article.managedObjectContext withRemoteDictionary:[NSDictionary dictionary]];
					
					NSError *error = nil;
					if (![file.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObjects:file, article, nil] error:&error])
						NSLog(@"Error obtaining permanent object ID: %@", error);
					
					[[article mutableOrderedSetValueForKey:@"files"] addObject:file];
					
					WAThumbnailMakeOptions options = 0;
					if (idx < 4) {
						options |= WAThumbnailMakeOptionMedium;
					}
					if (idx < 3) {
						options |= WAThumbnailMakeOptionSmall;
					}
					
					ALAsset *asset = (ALAsset *)obj;
					[file makeThumbnailsWithImage:[[asset defaultRepresentation] irImage] options:options];
					
					UIImage *extraSmallThumbnailImage = [UIImage imageWithCGImage:[asset thumbnail]];
					file.extraSmallThumbnailFilePath = [[[WADataStore defaultStore] persistentFileURLForData:UIImageJPEGRepresentation(extraSmallThumbnailImage, 0.85f) extension:@"jpeg"] path];
					
					file.assetURL = [[[asset defaultRepresentation] url] absoluteString];
					file.resourceType = (NSString *)kUTTypeImage;
					file.timestamp = [asset valueForProperty:ALAssetPropertyDate];
					file.importTime = importTime;

					NSDictionary *exifData = [[[asset defaultRepresentation] metadata] objectForKey:@"{Exif}"];
					NSDictionary *tiffData =	[[[asset defaultRepresentation] metadata] objectForKey:@"{TIFF}"];
					NSDictionary *gpsData = [[[asset defaultRepresentation] metadata] objectForKey:@"{GPS}"];
					WAFileExif *exif = (WAFileExif *)[WAFileExif objectInsertingIntoContext:file.managedObjectContext withRemoteDictionary:@{}];
					if (exifData) {
						exif.dateTimeOriginal = [exifData objectForKey:@"DateTimeOriginal"];
						exif.dateTimeDigitized = [exifData objectForKey:@"DateTimeDigitized"];
						exif.exposureTime = [exifData	objectForKey:@"ExposureTime"];
						exif.fNumber = [exifData objectForKey:@"FNumber"];
						exif.apertureValue = [exifData objectForKey:@"ApertureValue"];
						exif.focalLength = [exifData objectForKey:@"FocalLength"];
						exif.flash = [exifData objectForKey:@"Flash"];
						if ([exifData objectForKey:@"ISOSpeedRatings"] && [[exifData objectForKey:@"ISOSpeedRatings"] count] > 0) {
							exif.isoSpeedRatings = [[exifData objectForKey:@"ISOSpeedRatings"] objectAtIndex:0];
						}
						exif.colorSpace = [exifData objectForKey:@"ColorSpace"];
						exif.whiteBalance = [exifData objectForKey:@"WhiteBalance"];
					}
					if (tiffData) {
						exif.dateTime = [tiffData objectForKey:@"DateTime"];
						exif.model = [tiffData objectForKey:@"Model"];
						exif.make = [tiffData objectForKey:@"Make"];
					}
					if (gpsData) {
						exif.gpsLongitude = [gpsData objectForKey:@"Longitude"];
						exif.gpsLatitude = [gpsData objectForKey:@"Latitude"];
					}
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
				wSelf.lastImportedArticle = article;
			} else {
				NSLog(@"Error saving: %s %@", __PRETTY_FUNCTION__, savingError);
			}
			
			return wSelf.canceled;

		} onComplete:^{
			
			wSelf.finished = YES;
			aCallbackBlock();
			
		} onFailure:^(NSError *error) {
			
			NSLog(@"Unable to enumerate saved photos: %s %@", __PRETTY_FUNCTION__, error);
			wSelf.finished = YES;
			aCallbackBlock();

		}];

	}];
	
}

- (void)dealloc {

	[self irRemoveObserverBlocksForKeyPath:@"finished"];

}

@end
