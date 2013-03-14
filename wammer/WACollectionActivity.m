//
//  WACollectionActivity.m
//  wammer
//
//  Created by Shen Steven on 3/13/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WACollectionActivity.h"
#import "WACollection.h"
#import "WADataStore.h"
#import "WAFile+LazyImages.h"

@interface WACollectionActivity ()

@property (nonatomic, strong) WACollection *collection;
@property (nonatomic, strong) NSMutableArray *images;

@end

@implementation WACollectionActivity

- (id) initWithCollectionID:(NSManagedObjectID*)collectionID {

  self = [super init];
  if (self) {
    WADataStore *ds = [WADataStore defaultStore];
    self.collection = (WACollection*)[[ds disposableMOC] objectWithID:collectionID];
  }
  return self;
  
}

- (NSString *) activityType {
  return @"WACollection";
}

- (NSString*) activityTitle {
  return self.collection.title;
}

- (UIImage*) activityImage {
  if (self.collection.cover)
    return [self.collection.cover smallThumbnailImage];
  else if (self.collection.files.count)
    return [self.collection.files[0] smallThumbnailImage];
  return [UIImage imageNamed:@"PhotosIcon"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
  return (activityItems.count>0);
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
  NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
  __weak WACollectionActivity *wSelf = self;
  self.images = [@[] mutableCopy];
  
  [activityItems enumerateObjectsUsingBlock:^(NSManagedObjectID *obj, NSUInteger idx, BOOL *stop) {
    WAFile *file = (WAFile*)[context objectWithID:obj];
    [wSelf.images addObject:[file smallThumbnailImage]];
  }];
}

- (void)performActivity {
  
  if (self.images.count) {
    // add to collection
  }
  
}
@end
