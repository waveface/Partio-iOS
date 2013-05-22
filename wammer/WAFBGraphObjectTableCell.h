//
//  WAFBGraphObjectTableCell.h
//  wammer
//
//  Created by Greener Chen on 13/5/16.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <FBGraphObjectTableCell.h>

@interface WAFBGraphObjectTableCell : FBGraphObjectTableCell

@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *titleSuffix;
@property (nonatomic) BOOL boldTitle;
@property (nonatomic) BOOL boldTitleSuffix;

@property (copy, nonatomic) NSString *subtitle;
@property (retain, nonatomic) UIImage *picture;

+ (CGFloat)rowHeight;

@end
