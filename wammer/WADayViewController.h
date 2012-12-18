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

typedef NS_ENUM(NSInteger, WADayViewStyle) {
	WADayViewStyleTimeline,
	WADayViewStylePhotoStream,
	WADayViewStyleDocumentStream
};

typedef void (^completionBlock) (NSArray *days);

@interface WADayViewController : UIViewController <IRPaginatedViewDelegate, IIViewDeckControllerDelegate>


- (id)initWithClassNamed: (Class)containerClass;
- (void)jumpToRecentDay;
- (BOOL)jumpToDate:(NSDate*)date animated:(BOOL)animated;
- (void)loadDaysWithStyle:(WADayViewStyle)dayViewStyle From:(NSDate *)fromDate to:(NSDate *)toDate completionBlock:(completionBlock)block;

@end
