//
//  WAArticleView+ReuseSupport.h
//  wammer
//
//  Created by Evadne Wu on 6/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAArticleView.h"
#import "IRObjectQueue.h"

@interface WAArticleView (ReuseSupport) <IRQueueableObject>

@property (nonatomic, readwrite, copy) NSString *reuseIdentifier;

@end
