//
//  WATimelineWindowController.h
//  wammer
//
//  Created by Evadne Wu on 10/9/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WATimelineWindowController : NSWindowController

+ (id) sharedController;

@property (nonatomic, readwrite, retain) IBOutlet NSTableView *tableView;

@end
