//
//  WATimelineWindowController.h
//  wammer
//
//  Created by Evadne Wu on 10/9/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WATimelineWindowController : NSWindowController <NSTableViewDelegate>

+ (id) sharedController;

@property (nonatomic, readwrite, retain) IBOutlet NSTableView *tableView;
@property (nonatomic, readwrite, retain) IBOutlet NSArrayController *arrayController;

@property (nonatomic, readwrite, retain) NSManagedObjectContext *managedObjectContext;

@end
