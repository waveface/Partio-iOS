//
//  WARepresentedFilePickerViewController.h
//  wammer
//
//  Created by Evadne Wu on 4/5/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "IRViewController.h"

@interface WARepresentedFilePickerViewController : IRViewController

+ (id) controllerWithObjectURI:(NSURL *)objectURI completion:(void(^)(NSURL *selectedFileURI))block;

@end
