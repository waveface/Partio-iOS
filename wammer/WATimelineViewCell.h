//
//  WAPostViewCellPad.h
//  wammer
//
//  Created by Shen Steven on 11/20/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAArticle.h"
#import "IRLabel.h"

@interface WATimelineViewCell : UICollectionViewCell

@property (nonatomic, strong) WAArticle *representedArticle;
@property (nonatomic, readwrite, strong) IBOutlet IRLabel *commentLabel;
- (void) setRepresentedArticle:(WAArticle *)representedArticle onQueue:(NSOperationQueue*)displayQueue;
@end
