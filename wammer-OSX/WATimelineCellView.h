//
//  WATimelineCellView.h
//  wammer-OSX
//
//  Created by Evadne Wu on 10/10/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "WAArticle.h"

@interface WATimelineCellView : NSTableCellView

@property (retain) WAArticle *objectValue;

@end
