//
//  WAStationDiscoveryFeedbackViewController.h
//  wammer
//
//  Created by Evadne Wu on 11/30/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IRAction;

@interface WAStationDiscoveryFeedbackViewController : UIViewController

@property (retain, nonatomic) IBOutletCollection(UILabel) NSArray *interfaceLabels;
@property (nonatomic, readwrite, retain) IRAction *dismissalAction;

- (UINavigationController *) wrappingNavigationController;

@end
