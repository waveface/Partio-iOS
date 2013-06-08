//
//  WAPartioTokenField.h
//  wammer
//
//  Created by Greener Chen on 13/6/4.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAPartioTokenFieldCell.h"

@interface WAPartioTokenField : UITextField <UITextFieldDelegate> 

@property (nonatomic, readonly, strong) NSArray *cellViews;
@property (nonatomic, weak) WAPartioTokenFieldCell *selectedCell;
@property (nonatomic, readonly) NSInteger lineCount;

- (void)addCellWithObject:(id)object;
- (void)removeCellWithObject:(id)object;
- (void)removeAllCells;
- (void)removeSelectedCell;
- (void)scrollToVisibleLine:(BOOL)animated;
- (void)scrollToEditingLine:(BOOL)animated;
- (void)updateHeight;

@end
