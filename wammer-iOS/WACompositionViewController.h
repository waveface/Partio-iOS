//
//  WACompositionViewController.h
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@protocol WACompositionViewControllerSegment <NSObject>
@property (nonatomic, readonly, retain) UIViewController *backingViewController;
@property (nonatomic, readwrite, retain) NSManagedObject *representedObject;
@end

@interface WACompositionViewController : UIViewController
- (void) registerSegment:(id<WACompositionViewControllerSegment>)aSegment;
@end

@interface WACompositionEditingViewController : UIViewController <WACompositionViewControllerSegment>
@end

@interface WACompositionPreviewingViewController : UIViewController <WACompositionViewControllerSegment>
@end
