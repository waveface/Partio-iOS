//
//  WAPartioTokenFieldCell.m
//  wammer
//
//  Created by Greener Chen on 13/6/4.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAPartioTokenFieldCell.h"

static const CGFloat kMarginX = 8.f;
static const CGFloat kMarginY = 4.f;
static const CGFloat kMaxWidth = 250.f;

@interface WAPartioTokenFieldCell()

@property (nonatomic, weak) UIButton *buttonView;

@end


@implementation WAPartioTokenFieldCell

- (id)init
{
  self = [super init];
  if (self) {
    // Initialization code
    self.buttonView = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.buttonView setBackgroundImage:[self imageWithColor:[UIColor colorWithRed:117/255.f green:193/255.f blue:166/255.f alpha:1.f]] forState:UIControlStateNormal];
    [self.buttonView setBackgroundImage:[self imageWithColor:[UIColor colorWithRed:70/255.f green:130/255.f blue:118/255.f alpha:1.f]] forState:UIControlStateSelected];
    [self.buttonView addTarget:self action:@selector(toggleCell:) forControlEvents:UIControlEventTouchUpInside];
    [self.buttonView setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.buttonView.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.font = [UIFont fontWithName:@"OpenSans-Regular" size:16.f];
    [self.buttonView.layer setCornerRadius:14.f];
    [self.buttonView setClipsToBounds:YES];
    
    [self addSubview:self.buttonView];
    
    self.delegate = self;
  }
  return self;
}

- (UIImage *)imageWithColor:(UIColor *)color {
  CGRect rect = CGRectMake(0.f, 0.f, 1.f, 1.f);
  UIGraphicsBeginImageContext(rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  CGContextSetFillColorWithColor(context, [color CGColor]);
  CGContextFillRect(context, rect);
  
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return image;
}

#pragma mark - properties

- (NSString *)text
{
  return self.buttonView.titleLabel.text;
}

- (void)setText:(NSString *)text
{
  [self.buttonView setTitle:text forState:UIControlStateNormal];
  [self sizeToFit:[self.text sizeWithFont:self.font]];
}

- (UIFont *)font
{
  return self.buttonView.titleLabel.font;
}

- (void)setFont:(UIFont *)font
{
  self.buttonView.titleLabel.font = font;
}

- (void)toggleCell:(UIButton *)sender
{
  self.selected = !sender.selected;
  
  if ([self.delegate respondsToSelector:@selector(tokenFieldCellSelectedStateDidChange:)]) {
    [self.delegate tokenFieldCellSelectedStateDidChange:self];
  }
}

- (void)setSelected:(BOOL)selected
{
  self.buttonView.selected = selected;
}

- (BOOL)selected
{
  return self.buttonView.selected;
}

#pragma mark - UIView

- (CGSize)sizeToFit:(CGSize)size
{
  if (self.text) {
    CGSize buttonSize = [self.text sizeWithFont:self.font];
    CGFloat width = buttonSize.width + 2*kMarginX;
    self.buttonView.frame = CGRectMake(self.buttonView.frame.origin.x,
                                       self.buttonView.frame.origin.y,
                                       (width > kMaxWidth)? kMaxWidth : width,
                                       buttonSize.height + 2*kMarginY);
    
    self.frame = self.buttonView.frame;
    return CGSizeMake((width > kMaxWidth)? kMaxWidth : width, buttonSize.height + 2*kMarginY);
  } else {
    return size;
  }
}

@end
