//
//  WATimelineIndexView.h
//  wammer
//
//  Created by Shen Steven on 4/6/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WATimelineIndexLabel : UILabel
@property (nonatomic, assign) CGFloat relativePercent;
@end

@class WATimelineIndexView;
@protocol WATimelineIndexDataSource <NSObject>

@required
- (NSInteger) numberOfIndexicsForIndexView:(WATimelineIndexView*)indexView;
- (WATimelineIndexLabel *) labelForIndex:(NSInteger)index inIndexView:(WATimelineIndexView*)indexView;

@end

@interface WATimelineIndexView : UIView

- (void) reloadViews;
@property (nonatomic, weak) IBOutlet id<WATimelineIndexDataSource> dataSource;
@property (nonatomic, assign) CGFloat percentage;

@end
