//
//  WAComposition.h
//  wammer
//
//  Created by Evadne Wu on 12/18/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "WAArticle.h"
#import "WAFile.h"

@interface WAComposition : NSDocument

- (IBAction) handleSend:(id)sender;

@property (assign) IBOutlet NSTextView *textView;
@property (assign) IBOutlet NSProgressIndicator *spinner;
@property (assign) IBOutlet NSCollectionView *collectionView;

@end
