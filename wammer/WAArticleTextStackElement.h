//
//  WAArticleTextStackElement.h
//  wammer
//
//  Created by Evadne Wu on 3/2/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAArticleTextStackCell.h"


@class WAArticleTextStackElement;
@protocol WAArticleTextStackElementDelegate <NSObject>

- (void) textStackElement:(WAArticleTextStackElement *)element didRequestContentSizeToggle:(id)sender;

@end


@class WAArticleTextEmphasisLabel;
@interface WAArticleTextStackElement : WAArticleTextStackCell

@property (nonatomic, readonly, retain) WAArticleTextEmphasisLabel *textStackCellLabel;
@property (nonatomic, readwrite, assign) id<WAArticleTextStackElementDelegate> delegate;

@end
