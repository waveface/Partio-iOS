//
//  WAFBGraphObjectTableCell.m
//  wammer
//
//  Created by Greener Chen on 13/5/16.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAFBGraphObjectTableCell.h"

@interface FBGraphObjectTableCell()

@property (nonatomic, retain) IBOutlet UIImageView *pictureView;
@property (nonatomic, retain) UILabel* titleSuffixLabel;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;

- (void)updateFonts;

@end

@implementation WAFBGraphObjectTableCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

static const CGFloat titleFontHeight = 16;
static const CGFloat subtitleFontHeight = 12;
static const CGFloat pictureEdge = 35;
static const CGFloat pictureMargin = 4;
static const CGFloat horizontalMargin = 4;
static const CGFloat titleTopNoSubtitle = 11;
static const CGFloat titleTopWithSubtitle = 3;
static const CGFloat subtitleTop = 23;
static const CGFloat titleHeight = titleFontHeight * 1.25;
static const CGFloat subtitleHeight = subtitleFontHeight * 1.25;



#pragma mark - Lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString*)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    // Picture
    self.pictureView.layer.cornerRadius = 3.f;
    self.pictureView.clipsToBounds = YES;
    
    // Subtitle
    self.detailTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.detailTextLabel.textColor = [UIColor whiteColor];
    self.detailTextLabel.font = [UIFont systemFontOfSize:subtitleFontHeight];
    
    // Title
    self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.textLabel.textColor = [UIColor whiteColor];
    self.textLabel.font = [UIFont systemFontOfSize:titleFontHeight];
    
    // Content View
    self.contentView.clipsToBounds = YES;
  }
  
  return self;
}

#pragma mark -

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  [self updateFonts];
  
  BOOL hasPicture = (self.picture != nil);
  BOOL hasSubtitle = (self.subtitle != nil);
  BOOL hasTitleSuffix = (self.titleSuffix != nil);
  
  CGFloat pictureWidth = hasPicture ? pictureEdge : 0;
  CGSize cellSize = self.contentView.bounds.size;
  CGFloat textLeft = (hasPicture ? ((2 * pictureMargin) + pictureWidth) : 0) + horizontalMargin;
  CGFloat textWidth = cellSize.width - (textLeft + horizontalMargin);
  CGFloat titleTop = hasSubtitle ? titleTopWithSubtitle : titleTopNoSubtitle;
  
  self.pictureView.frame = CGRectMake(pictureMargin, pictureMargin, pictureWidth, pictureEdge);
  self.detailTextLabel.frame = CGRectMake(textLeft, subtitleTop, textWidth, subtitleHeight);
  if (!hasTitleSuffix) {
    self.textLabel.frame = CGRectMake(textLeft, titleTop, textWidth, titleHeight);
  } else {
    CGSize titleSize = [self.textLabel.text sizeWithFont:self.textLabel.font];
    CGSize spaceSize = [@" " sizeWithFont:self.textLabel.font];
    CGFloat titleWidth = titleSize.width + spaceSize.width;
    self.textLabel.frame = CGRectMake(textLeft, titleTop, titleWidth, titleHeight);
    
    CGFloat titleSuffixLeft = textLeft + titleWidth;
    CGFloat titleSuffixWidth = textWidth - titleWidth;
    self.titleSuffixLabel.frame = CGRectMake(titleSuffixLeft, titleTop, titleSuffixWidth, titleHeight);
  }
  
  [self.pictureView setHidden:!(hasPicture)];
  [self.detailTextLabel setHidden:!(hasSubtitle)];
  [self.titleSuffixLabel setHidden:!(hasTitleSuffix)];
}

+ (CGFloat)rowHeight
{
  return pictureEdge + (2 * pictureMargin) + 1;
}

- (void)startAnimatingActivityIndicator {
  CGRect cellBounds = self.bounds;
  if (!self.activityIndicator) {
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    activityIndicator.autoresizingMask =
    (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    
    self.activityIndicator = activityIndicator;
    [self addSubview:activityIndicator];
  }
  
  self.activityIndicator.center = CGPointMake(CGRectGetMidX(cellBounds), CGRectGetMidY(cellBounds));
  
  [self.activityIndicator startAnimating];
}

- (void)stopAnimatingActivityIndicator {
  if (self.activityIndicator) {
    [self.activityIndicator stopAnimating];
  }
}

- (void)updateFonts {
  if (self.boldTitle) {
    self.textLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:titleFontHeight];
  } else {
    self.textLabel.font = [UIFont fontWithName:@"OpenSans-Regular" size:titleFontHeight];
  }
  
  if (self.boldTitleSuffix) {
    self.titleSuffixLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:titleFontHeight];
  } else {
    self.titleSuffixLabel.font = [UIFont fontWithName:@"OpenSans-Regular" size:titleFontHeight];
  }
  self.titleSuffixLabel.textColor = [UIColor whiteColor];
  self.titleSuffixLabel.backgroundColor = [UIColor clearColor];
}

- (void)createTitleSuffixLabel {
  if (!self.titleSuffixLabel) {
    UILabel *titleSuffixLabel = [[UILabel alloc] init];
    titleSuffixLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.contentView addSubview:titleSuffixLabel];
    
    self.titleSuffixLabel = titleSuffixLabel;
    
  }
}
#pragma mark - Properties

- (UIImage *)picture
{
  return self.pictureView.image;
}

- (void)setPicture:(UIImage *)picture
{
  self.pictureView.image = picture;
  [self setNeedsLayout];
}

- (NSString*)subtitle
{
  return self.detailTextLabel.text;
}

- (void)setSubtitle:(NSString *)subtitle
{
  self.detailTextLabel.text = subtitle;
  [self setNeedsLayout];
}

- (NSString*)title
{
  return self.textLabel.text;
}

- (void)setTitle:(NSString *)title
{
  self.textLabel.text = title;
  [self setNeedsLayout];
}

- (NSString*)titleSuffix
{
  return self.titleSuffixLabel.text;
}

- (void)setTitleSuffix:(NSString *)titleSuffix
{
  if (titleSuffix) {
    [self createTitleSuffixLabel];
  }
  if (self.titleSuffixLabel) {
    self.titleSuffixLabel.text = titleSuffix;
  }
  [self setNeedsLayout];
}

@end
