//
//  WASwipeableTableViewController.h
//  wammer
//
//  Created by Shen Steven on 10/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IRPaginatedView.h"
#import "IIViewDeckController.h"

@interface WADayViewController : UIViewController <IRPaginatedViewDelegate, IIViewDeckControllerDelegate, NSFetchedResultsControllerDelegate>

- (id)initWithClassNamed: (Class)containerClass;
- (void)jumpToToday;

@end
