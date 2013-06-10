//
//  WAPartioTokenFieldCell.h
//  wammer
//
//  Created by Greener Chen on 13/6/4.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WAPartioTokenFieldCellDelegate;

@interface WAPartioTokenFieldCell : UIView <WAPartioTokenFieldCellDelegate>

@property (nonatomic, weak) id object;
@property (nonatomic, weak) NSString *text;
@property (nonatomic, weak) UIFont *font;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, strong) id<WAPartioTokenFieldCellDelegate>delegate;

@end


@protocol WAPartioTokenFieldCellDelegate <NSObject>

- (void)tokenFieldCellSelectedStateDidChange:(WAPartioTokenFieldCell *)cell;

@end