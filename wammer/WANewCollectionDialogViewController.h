//
//  WANewCollectionDialogViewController.h
//  wammer
//
//  Created by Shen Steven on 3/13/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAUser.h"

@interface WANewCollectionDialogViewController : UIViewController

- (id) initWithCompletionBlock:(void(^)(NSString*))completionBlock;

@end
