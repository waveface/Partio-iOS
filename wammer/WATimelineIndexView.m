//
//  WATimelineIndexView.m
//  wammer
//
//  Created by Shen Steven on 4/6/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WATimelineIndexView.h"

@interface WATimelineIndexLabel ()
- (void) show;
- (void) hide;
@property (nonatomic, assign) BOOL showing;
@end

@implementation WATimelineIndexLabel

- (id) initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  
  if (self) {
    self.showing = NO;
    self.alpha = 0.0f;
    self.textAlignment = NSTextAlignmentCenter;
  }
  
  return self;
}

- (void) show {
  if (!self.showing) {
    
    [UIView animateWithDuration:0.4
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionShowHideTransitionViews
                     animations:^{
                       self.alpha = 1.0f;
                     } completion:^(BOOL finished) {
                     }];
    self.showing = YES;
    
  }
}

- (void) hide {
  if (self.showing) {
    [UIView animateWithDuration:1
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionShowHideTransitionViews
                     animations:^{
                       self.alpha = 0.0f;
                     } completion:^(BOOL finished) {
                     }];
    
    self.showing = NO;
  }
}

@end



@interface WATimelineIndexView ()

@property (nonatomic, strong) NSMutableArray *indexics;
@property (nonatomic, strong) NSMutableArray *labels;
@property (nonatomic, strong) UIImageView *dot;

@end
@implementation WATimelineIndexView

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    [self initialize];
  }
  return self;
}

- (void) awakeFromNib {
  
  [self initialize];
  
}

- (void) initialize {
    
  self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
  self.layer.cornerRadius = self.frame.size.width/2;
  self.dot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"clock"]];
  CGRect newRect = CGRectMake(self.frame.size.width/2-self.dot.frame.size.width/2, 0, self.dot.frame.size.width, self.dot.frame.size.height);
  self.dot.frame = newRect;
  [self addSubview:self.dot];
    
  self.indexics = [NSMutableArray array];
  self.labels = [NSMutableArray array];
}


- (void) reloadViews {
  if (self.dataSource) {
    // remove all subview labels
    if (self.labels) {
      [self.labels enumerateObjectsUsingBlock:^(WATimelineIndexLabel *label, NSUInteger idx, BOOL *stop) {
        [label removeFromSuperview];
      }];
    }
    [self.indexics removeAllObjects];
    [self.labels removeAllObjects];
    
    NSInteger numOfItems = [self.dataSource numberOfIndexicsForIndexView:self];
    if (numOfItems == 0)
      return;
    self.indexics = [NSMutableArray arrayWithCapacity:numOfItems];
    self.labels = [NSMutableArray arrayWithCapacity:numOfItems];
    
    for (NSInteger i = 0; i < numOfItems; i ++) {
      WATimelineIndexLabel *aLabel = [self.dataSource labelForIndex:i inIndexView:self] ;
      if (!aLabel)
        continue;
      [self.indexics addObject:@(aLabel.relativePercent)];
      aLabel.backgroundColor = [UIColor colorWithRed:0.168 green:0.168 blue:0.168 alpha:0.8];
      aLabel.textColor = [UIColor whiteColor];
      aLabel.textAlignment = NSTextAlignmentCenter;
      aLabel.frame = CGRectMake(-200, 0, 195, 22);
      aLabel.layer.cornerRadius = 3;
      aLabel.layer.shadowOffset = CGSizeMake(0, 0);
      aLabel.layer.shadowRadius = 3;
      aLabel.layer.shadowOpacity = 0.4;
      aLabel.layer.shadowColor = [UIColor blackColor].CGColor;
      aLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:12];
      [aLabel sizeToFit];
      [self addSubview:aLabel];
      CGRect newFrame = aLabel.frame;
      newFrame.origin.x = -5 - newFrame.size.width;
      aLabel.frame = newFrame;
      [self.labels addObject:aLabel];
    }
  }
}

- (NSInteger) indexForPercentage:(CGFloat)percentage {

  int i = 0;
  for (NSNumber *index in self.indexics) {
    CGFloat max = [index floatValue] + 0.01;
    CGFloat min = [index floatValue] - 0.005;
    
    if (percentage < max && percentage > min) {
      return i;
    }
    i++;
  }
  
  return NSNotFound;
}

- (void) setPercentage:(CGFloat)percentage {
  
  if (percentage < 0 || percentage > 1)
    return ;
  
  CGFloat newY = (self.frame.size.height*0.94) * percentage + (self.frame.size.height*0.02);
  CGRect newRect = CGRectMake(self.frame.size.width/2-self.dot.frame.size.width/2, newY - self.dot.frame.size.height/2, self.dot.frame.size.width, self.dot.frame.size.height);
  [UIView animateWithDuration:0.2 animations:^{
    self.dot.frame = newRect;
  }];
  
  NSInteger indexInRange = [self indexForPercentage:percentage];
  if (indexInRange != NSNotFound) {
    CGRect frame = ((WATimelineIndexLabel*)self.labels[indexInRange]).frame;
    frame.origin.y = newY - 11;
    ((WATimelineIndexLabel*)self.labels[indexInRange]).frame = frame;
    
    if (!((WATimelineIndexLabel*)self.labels[indexInRange]).showing)
      [((WATimelineIndexLabel*)self.labels[indexInRange]) show];
  }
  
  NSInteger preIndexInRange = [self indexForPercentage:_percentage];
  if (preIndexInRange != NSNotFound && ((WATimelineIndexLabel*)self.labels[preIndexInRange]).showing ) {
    [((WATimelineIndexLabel*)self.labels[preIndexInRange]) hide];
  }
  
  _percentage = percentage;

}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
