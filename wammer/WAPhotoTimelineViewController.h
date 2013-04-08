//
//  WAPhotoTimelineViewController.h
//  wammer
//
//  Created by Shen Steven on 4/5/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WAPhotoTimelineViewController : UIViewController

- (id) initWithAssets:(NSArray*)assets;
- (id) initWithArticle:(NSManagedObjectID *)managedObjectID;

@end
