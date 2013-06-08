//
//  WAPartioTextField.m
//  wammer
//
//  Created by Greener Chen on 13/6/4.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import "WAPartioTokenField.h"
#import "WAFBGraphUser.h"

static NSString* kEmpty = @" ";
static NSString* kSelected = @"`";

static const CGFloat kCellPaddingY = 4.f;
static const CGFloat kPaddingX = 8.f;
static const CGFloat kSpacingY = 6.f;
static const CGFloat kPaddingRatio = 1.75f;
static const CGFloat kClearButtonSize = 38.0f;
static const CGFloat kMinCursorWidth  = 10.0f;


@interface WAPartioTokenField()

@property (nonatomic) CGPoint originCursor;

@end

@implementation WAPartioTokenField
@synthesize cellViews;
@synthesize selectedCell;
@synthesize lineCount;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
      // Initialization code
      lineCount = 1;
      cellViews = [[NSArray alloc] init];
      self.originCursor = CGPointMake(kMinCursorWidth, 0.f);
      
    }
    return self;
}

#pragma mark - UITextFieldDelegate for text layout changing according to cell views

- (void)setText:(NSString*)text {
  if (cellViews) {
    [self updateHeight];
  }
  [super setText:text];
}

- (CGRect)textRectForBounds:(CGRect)bounds {
  if (cellViews.count && [self.text isEqualToString:kSelected]) {
    // Hide the cursor while a cell is selected
    return CGRectMake(-10, 0, 0, 0);
    
  } else {
    CGRect frame = CGRectOffset(bounds, self.originCursor.x, self.originCursor.y);
    frame.size.width -= (self.originCursor.x + kPaddingX + (self.rightView ? kClearButtonSize : 0));
    frame.size.height -= self.originCursor.y + kSpacingY + kCellPaddingY;
    return frame;
  }
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
  return [self textRectForBounds:bounds];
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds {
  return [self textRectForBounds:bounds];
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds {
  if (self.leftView) {
    return CGRectMake(
                      bounds.origin.x+kPaddingX, self.marginY,
                      self.leftView.frame.size.width, self.leftView.frame.size.height);
    
  } else {
    return bounds;
  }
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds {
  if (self.rightView) {
    return CGRectMake(bounds.size.width - kClearButtonSize, bounds.size.height - kClearButtonSize,
                      kClearButtonSize, kClearButtonSize);
    
  } else {
    return bounds;
  }
}

#pragma mark - layout

- (CGFloat)layoutCells
{
  CGFloat fontHeight = [@"text" sizeWithFont:self.font].height;
  CGFloat lineIncrement = fontHeight + kCellPaddingY*2 + kSpacingY;
  CGFloat marginY = floor(fontHeight/kPaddingRatio);
  CGFloat marginLeft = self.leftView
  ? self.leftView.frame.size.width
  : kPaddingX;
  CGFloat marginRight = kPaddingX + (self.rightView ? kClearButtonSize : 0);
  
  self.originCursor = CGPointMake(marginLeft, marginY);
  lineCount = 1;
  
  if (self.frame.size.width) {
    for (WAPartioTokenFieldCell *cell in cellViews) {
      [cell sizeToFit];
      
      CGFloat lineWidth = self.originCursor.x + cell.frame.size.width + marginRight;
      if (lineWidth >= self.frame.size.width) {
        self.originCursor = CGPointMake(marginLeft, self.originCursor.y+lineIncrement);
        ++lineCount;
      }
      
      cell.frame = CGRectMake(self.originCursor.x, self.originCursor.y-kCellPaddingY,
                              cell.frame.size.width, cell.frame.size.height);
      [cell.layer setCornerRadius:14.f];
      [cell setClipsToBounds:YES];

      self.originCursor = CGPointMake(self.originCursor.x + cell.frame.size.width + kPaddingX, self.originCursor.y);
    }
    
    CGFloat remainingWidth = self.frame.size.width - (self.originCursor.x + marginRight);
    if (remainingWidth < kMinCursorWidth) {
      self.originCursor = CGPointMake(marginLeft, self.originCursor.y + lineIncrement);
      ++lineCount;
    }
  }
  
  return self.originCursor.y + fontHeight + marginY;
}
                        
- (void)updateHeight
{
  CGFloat previousHeight = self.frame.size.height;
  CGFloat newHeight = [self layoutCells];
  if (previousHeight && newHeight != previousHeight) {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, newHeight);
    [self setNeedsDisplay];
    
    [UIView animateWithDuration:0.3f animations:^{
      [self invalidateIntrinsicContentSize];
      //[self scrollToVisibleLine:YES];
    }];
    
  }
  
  
}

- (CGSize)intrinsicContentSize
{
  if (self.editing) {
    return CGSizeMake(self.frame.size.width, [self layoutCells]);
  } else {
    return self.frame.size;
  }
}

- (CGFloat)marginY {
  return floor([@"text" sizeWithFont:self.font].height/kPaddingRatio);
}

- (CGFloat)topOfLine:(int)lineNumber {
  if (lineNumber == 0) {
    return 0;
    
  } else {
    CGFloat ttLineHeight = [@"text" sizeWithFont:self.font].height;
    CGFloat lineSpacing = kCellPaddingY*2 + kSpacingY;
    CGFloat marginY = floor(ttLineHeight/kPaddingRatio);
    CGFloat lineTop = marginY + ttLineHeight*lineNumber + lineSpacing*lineNumber;
    return lineTop - lineSpacing;
  }
}

- (CGFloat)centerOfLine:(int)lineNumber {
  CGFloat lineTop = [self topOfLine:lineNumber];
  CGFloat ttLineHeight = [@"text" sizeWithFont:self.font].height + kCellPaddingY*2 + kSpacingY;
  return lineTop + floor(ttLineHeight/2);
}

- (CGFloat)heightWithLines:(int)lines {
  CGFloat ttLineHeight = [@"text" sizeWithFont:self.font].height;
  CGFloat lineSpacing = kCellPaddingY*2 + kSpacingY;
  CGFloat marginY = floor(ttLineHeight/kPaddingRatio);
  return marginY + ttLineHeight*lines + lineSpacing*(lines ? lines-1 : 0) + marginY;
}

#pragma mark - UIView

- (void)layoutSubviews {

  if (cellViews) {
    [self layoutCells];
    
  } else {
    self.originCursor = CGPointMake(kPaddingX, [self marginY]);
    if (self.leftView) {
      self.originCursor = CGPointMake(self.leftView.frame.size.width + kPaddingX/2, self.originCursor.y);
    }
  }

  [super layoutSubviews];

}

- (CGSize)sizeThatFits:(CGSize)size {
  [self layoutIfNeeded];
  CGFloat height = [self heightWithLines:lineCount];
  return CGSizeMake(size.width, height);
}

#pragma mark - manage cells

- (void)addCellWithObject:(id)object
{
  WAPartioTokenFieldCell *cell = [[WAPartioTokenFieldCell alloc] init];
  cell.object = object;
  cell.text = [self titleOfObject:object];
  NSMutableArray *cells = [NSMutableArray array];
  if (cellViews) {
    cells = [cellViews mutableCopy];
  }
  [cells addObject:cell];
  cellViews = [cells copy];
  [self addSubview:cell];
  
  self.text = @"";
  
}

- (void)removeCellWithObject:(id)object
{
  NSMutableArray *cells = [NSMutableArray array];
  if (cellViews) {
    cells = [cellViews mutableCopy];
    for (NSInteger i = 0; i < cells.count; i++) {
      WAPartioTokenFieldCell *cell = cells[i];
      //FIXME: some cell's object becomes nil
      if ([cell.object isEqual:object]) {
        [cells removeObject:cell];
        [cell removeFromSuperview];
        if ([selectedCell isEqual:cell]) {
          selectedCell = nil;
        }
        break;
      }
    }
    cellViews = [cells copy];
  }
  self.text = @"";
}

- (void)removeAllCells
{
  cellViews = @[];
  selectedCell = nil;
}

- (void)removeSelectedCell:(WAPartioTokenFieldCell *)cell
{
  NSMutableArray *cells = [cellViews mutableCopy];
  [cells removeObject:cell];
  cellViews = [cells copy];
  
  selectedCell = nil;
}

- (void)selectLastCell
{
  selectedCell = [cellViews lastObject];
}

- (void)setSelectedCell:(WAPartioTokenFieldCell *)cell
{
  if (selectedCell) {
    selectedCell.selected = NO;
  }
  
  selectedCell = cell;
  if (selectedCell) {
    selectedCell.selected = YES;
    self.text = kSelected;
  } else if (self.cellViews.count) {
    self.text = @"";
  }
}

- (NSString *)titleOfObject:(id)object
{
  if ([object isKindOfClass:[FBGraphObject class]]) {
    return object[@"name"];
  } else {
    return nil;
  }
}

//- (void)scrollToVisibleLine:(BOOL)animated
//{
//  if (self.editing) {
//    UIScrollView* scrollView = (UIScrollView*)[self ancestorOrSelfWithClass:[UIScrollView class]];
//    if (scrollView) {
//      [scrollView setContentOffset:CGPointMake(0, self.top) animated:animated];
//    }
//  }
//}
//
//- (void)scrollToEditingLine:(BOOL)animated
//{
//  UIScrollView* scrollView = (UIScrollView*)[self ancestorOrSelfWithClass:[UIScrollView class]];
//  if (scrollView) {
//    CGFloat offset = (lineCount == 1 ? 0 : [self topOfLine:lineCount-1]);
//    [scrollView setContentOffset:CGPointMake(0, self.top+offset) animated:animated];
//  }
//}


@end
