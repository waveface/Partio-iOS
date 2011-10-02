//
//  WAUserSelectionViewController.h
//  Wammer
//
//  Created by Evadne Wu on 6/22/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface WAUserSelectionViewController : UITableViewController

+ (WAUserSelectionViewController *) controllerWithElectibleUsers:(NSArray *)users onSelection:(void(^)(NSURL *pickedUser))completion;

@property (nonatomic, readwrite, retain) NSArray *eligibleUsers;
@property (nonatomic, readwrite, copy) void (^completionBlock)(NSURL *pickedUser);

@end
