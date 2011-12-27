//
//  WAArticleViewController+Subclasses.h
//  wammer
//
//  Created by Evadne Wu on 12/22/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAArticleViewController.h"

@interface WAArticleViewController (Subclasses)

@property (nonatomic, readonly, retain) NSURL *representedObjectURI;
@property (nonatomic, readonly, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly, retain) WAArticle *article;

@end
