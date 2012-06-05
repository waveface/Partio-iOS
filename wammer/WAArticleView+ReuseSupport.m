//
//  WAArticleView+ReuseSupport.m
//  wammer
//
//  Created by Evadne Wu on 6/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAArticleView+ReuseSupport.h"
#import <objc/runtime.h>

static NSString * const kReuseIdentifier = @"-[WAArticleView(ReuseSupport) reuseIdentifier]";


@implementation WAArticleView (ReuseSupport)

- (NSString *) reuseIdentifier {

	return objc_getAssociatedObject(self, &kReuseIdentifier);

}

- (void) setReuseIdentifier:(NSString *)newIdentifier {

	objc_setAssociatedObject(self, &kReuseIdentifier, newIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);

}

@end
