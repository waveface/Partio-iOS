//
//  WAProgressIndicatorWindow.h
//  wammer
//
//  Created by Evadne Wu on 12/19/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WAProgressIndicatorWindow : NSWindow

+ (id) fromNib;

@property (assign) IBOutlet NSProgressIndicator *progressIndicator;

@end
