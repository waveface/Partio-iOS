//
//  WAAddCollectionActivity.m
//  wammer
//
//  Created by Shen Steven on 3/13/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WANewCollectionActivity.h"
#import "WANewCollectionDialogViewController.h"
#import "WARemoteInterface.h"
#import "WADataStore.h"
#import "WACollection.h"
#import "WACollection+RemoteOperations.h"

@interface WANewCollectionActivity()
@property(nonatomic, strong) NSMutableArray *files;
@property (nonatomic, strong) NSManagedObjectContext *context;
@end
@implementation WANewCollectionActivity

- (NSString *) activityType {
  return @"AddCollection";
}

- (NSString*) activityTitle {
  return @"New Collection";
}

- (UIImage*) activityImage {
  return [UIImage imageNamed:@"Create"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
  return (activityItems.count>0);
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
  self.context = [[WADataStore defaultStore] disposableMOC];
  __weak WANewCollectionActivity *wSelf = self;
  self.files = [@[] mutableCopy];
  
  [activityItems enumerateObjectsUsingBlock:^(NSManagedObjectID *obj, NSUInteger idx, BOOL *stop) {
    WAFile *file = (WAFile*)[self.context objectWithID:obj];
    [wSelf.files addObject:file];
  }];
 
}

- (UIViewController*) activityViewController {
  __weak WANewCollectionActivity *wSelf = self;
  WANewCollectionDialogViewController *vc = [[WANewCollectionDialogViewController alloc]
                                             initWithCompletionBlock:^(NSString *collectionName) {
                                               
                                               wSelf.context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
                                               WACollection *collection = [[WACollection alloc] initWithName:collectionName
                                                                                                   withFiles:wSelf.files
                                                                                      inManagedObjectContext:wSelf.context];
                                               collection.creator = [[WADataStore defaultStore] mainUserInContext:wSelf.context];
                                               NSError *error;
                                               if ([wSelf.context save:&error]==NO){
                                                 NSLog(@"Save error: %@", error);
                                               }

                                               [wSelf activityDidFinish:YES];
                                             }];
  return vc;
}
@end
