//
//  IRLabelTestingViewController.h
//  wammer
//
//  Created by Evadne Wu on 10/19/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IRLabel.h"

@interface IRLabelTestingViewController : UIViewController

@property (nonatomic, readwrite, retain) IBOutletCollection(IRLabel) NSArray *testLabels;

@end
