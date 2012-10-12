//
//  WACacheManager.m
//  wammer
//
//  Created by kchiu on 12/10/8.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WACacheManager.h"
#import "WADataStore.h"
#import "WAFile+WAConstants.h"

NSString * const kWACacheConstructionFinished = @"WACacheConstructionFinished";
NSString * const kWACacheFilePathKey = @"filePathKey";
NSString * const kWACacheFilePath = @"filePath";
NSUInteger const kLimitSize = 10*1024*1024; //10MB

@interface WACacheManager ()

@property (nonatomic, readwrite, assign) BOOL constructionFinished;
@property (nonatomic, readwrite, strong) NSManagedObjectContext *context;
@property (nonatomic, readwrite, strong) NSOperationQueue *queue;

+ (NSString *)archivePath;

- (void)handleApplicationDidEnterBackground:(NSNotification *)note;
- (void)initCacheEntities;

@end

@implementation WACacheManager

+ (WACacheManager *)sharedManager {

	static WACacheManager *returnedManager = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
		
		returnedManager = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self class] archivePath]];
		if (!returnedManager) {
			returnedManager = [[self alloc] init];
		}
    
	});
	
	return returnedManager;

}

- (id)init {

	self = [super init];
	if (self) {
		[self setConstructionFinished:NO];
		[self setContext:[[WADataStore defaultStore] disposableMOC]];
		[[self context] setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
		[self setQueue:[[NSOperationQueue alloc] init]];
		[[self queue] setMaxConcurrentOperationCount:1];
		[self initCacheEntities];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	}
	return self;

}

- (id)initWithCoder:(NSCoder *)aDecoder {

	self = [super init];
	if (self) {
		[self setConstructionFinished:[aDecoder decodeBoolForKey:kWACacheConstructionFinished]];
		[self setContext:[[WADataStore defaultStore] disposableMOC]];
		[[self context] setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
		[self setQueue:[[NSOperationQueue alloc] init]];
		[[self queue] setMaxConcurrentOperationCount:1];
		if (![self constructionFinished]) {
			[self initCacheEntities];
		}
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	}
	return self;

}

- (void)encodeWithCoder:(NSCoder *)aCoder {

	[aCoder encodeBool:[self constructionFinished] forKey:kWACacheConstructionFinished];

}

- (void)dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (void)handleApplicationDidEnterBackground:(NSNotification *)note {

	BOOL saved = [NSKeyedArchiver archiveRootObject:self toFile:[[self class] archivePath]];
	if (!saved) {
		NSLog(@"Unable to save WACacheManager");
	}

}

- (void)initCacheEntities {

	NSArray *files = [[WADataStore defaultStore] fetchAllFilesUsingContext:[self context]];
	for (WAFile *file in files) {
		if (![file caches]) {
			NSArray *pathKeys = @[kWAFileExtraSmallThumbnailFilePath, kWAFileSmallThumbnailFilePath, kWAFileThumbnailFilePath, kWAFileLargeThumbnailFilePath, kWAFileResourceFilePath];
			for (NSString *pathKey in pathKeys) {
				NSString *filePath = [file valueForKey:pathKey];
				if (filePath) {
					NSLog(@"touch attachment file at: %@", filePath);
				}
			}
		}
	}
	
	NSArray *ogImages = [[WADataStore defaultStore] fetchAllOGImagesUsingContext:[self context]];
	for (WAOpenGraphElementImage *ogImage in ogImages) {
		if (![ogImage cache]) {
			NSString *filePath = [ogImage imageFilePath];
			if (filePath) {
				NSLog(@"touch ogimage file at: %@", filePath);
			}
		}
	}

	__weak WACacheManager *wSelf = self;
	[[self queue] addOperationWithBlock:^{
		[wSelf setConstructionFinished:YES];
		NSLog(@"Cache entries initialized");
	}];

}

- (void)insertOrUpdateCacheWithRelationship:(NSURL *)relationshipURL filePath:(NSString *)filePath filePathKey:(NSString *)filePathKey {

	if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		NSLog(@"Non existing file at: %@", filePath);
	}
	__weak WACacheManager *wSelf = self;
	[[wSelf queue] addOperationWithBlock:^{

		id relatedObject = [[wSelf context] irManagedObjectForURI:relationshipURL];
		BOOL isWAFile = [relatedObject isKindOfClass:[WAFile class]];
		BOOL isWAOpenGraphElementImage = [relatedObject isKindOfClass:[WAOpenGraphElementImage class]];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@ && %K == %@", kWACacheFilePathKey, filePathKey, kWACacheFilePath, filePath];
		WACache *currentCache = [[WADataStore defaultStore] fetchCacheWithPredicate:predicate usingContext:[wSelf context]];
		WACache *savedCache = nil;
		if (currentCache) {
			
			[currentCache setLastAccessTime:[NSDate date]];
			
		} else {
			
			savedCache = [WACache objectInsertingIntoContext:[wSelf context] withRemoteDictionary:@{}];
			[savedCache setLastAccessTime:[NSDate date]];
			[savedCache setFilePath:filePath];
			[savedCache setFilePathKey:filePathKey];
			NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
			[savedCache setFileSize:[attributes objectForKey:NSFileSize]];
			
			if (isWAFile) {
				[savedCache setFile:(WAFile *)relatedObject];
			} else if (isWAOpenGraphElementImage) {
				[savedCache setOgimage:(WAOpenGraphElementImage *)relatedObject];
			}
			
		}
		
		NSError *error = nil;
		[[wSelf context] save:&error];
		if (error) {
			NSLog(@"Error saving: %s %@", __PRETTY_FUNCTION__, error);
		}

	}];
 
}

- (void)clearPurgeableFilesIfNeeded {

	__block NSUInteger totalSize = [[[WADataStore defaultStore] fetchTotalCacheSizeUsingContext:[self context]] unsignedIntegerValue];
	if (totalSize > kLimitSize) {

		NSLog(@"Total cache size is over %d, clear purgeable files now...", kLimitSize);
		__weak WACacheManager *wSelf = self;
		NSArray *caches = [[WADataStore defaultStore] fetchAllCachesUsingContext:[self context]];
		for (WACache *cache in caches) {
			[[self queue] addOperationWithBlock:^{
				if (totalSize <= kLimitSize) {
					return;
				}
				if ([[wSelf delegate] shouldPurgeCachedFile:cache]) {
					NSError *error = nil;
					if ([[NSFileManager defaultManager] fileExistsAtPath:[cache filePath]]) {
						[[NSFileManager defaultManager] removeItemAtPath:[cache filePath] error:&error];
						if (error) {
							NSLog(@"Unable to remove cached file: %s %@", __PRETTY_FUNCTION__, error);
							return;
						}
					}
					totalSize -= [[cache fileSize] unsignedIntegerValue];
					[[wSelf context] deleteObject:cache];
					error = nil;
					[[wSelf context] save:&error];
					if (error) {
						NSLog(@"Error saving: %s %@", __PRETTY_FUNCTION__, error);
					}
				}
			}];
		}

		[[self queue] addOperationWithBlock:^{
			NSLog(@"Purging finished, current total size is %d", totalSize);
		}];

	} else {

		NSLog(@"Total cache size is under %d, no need purging", kLimitSize);

	}
	
}

+ (NSString *)archivePath {

	NSArray *cacheDirectories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *cacheDirectory = [cacheDirectories objectAtIndex:0];
	return [cacheDirectory stringByAppendingPathComponent:@"cachemanager.archive"];

}
	
@end
