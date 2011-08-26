//
//  WATableViewCell.h
//  wammer-iOS
//
//  Created by Evadne Wu on 8/26/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WATableViewCell : UITableViewCell

@property (nonatomic, readwrite, copy) void(^onSetSelected)(WATableViewCell *self, BOOL selected, BOOL animated);
@property (nonatomic, readwrite, copy) void(^onSetEditing)(WATableViewCell *self, BOOL selected, BOOL animated);

@end
