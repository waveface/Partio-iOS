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

typedef NS_ENUM(NSUInteger, WADayViewSupportedStyle) {
	WAEventsViewStyle,
	WAPhotosViewStyle,
	WAWebpagesViewStyle,
	WADocumentsViewStyle,
};

@interface WADayViewController : UIViewController <IRPaginatedViewDelegate, IIViewDeckControllerDelegate>

- (id)initWithStyle: (WADayViewSupportedStyle)style;
- (void)jumpToRecentDay;
- (BOOL)jumpToDate:(NSDate*)date animated:(BOOL)animated;

@end
