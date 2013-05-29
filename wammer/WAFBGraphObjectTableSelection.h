//
//  WAFBGraphObjectTableSelection.h
//  wammer
//
//  Created by Greener Chen on 13/5/16.
//  Copyright (c) 2013年 Waveface. All rights reserved.
//

#import <FBGraphObjectTableSelection.h>

@interface WAFBGraphObjectTableSelection : FBGraphObjectTableSelection

- (void)selectItem:(FBGraphObject *)item;

@property (nonatomic, retain) NSArray *selection;

@end
