//
//  WADocumentStreamViewController.h
//  wammer
//
//  Created by kchiu on 12/12/5.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAFile.h"

@interface WADocumentStreamViewController : UICollectionViewController <NSFetchedResultsControllerDelegate>

+ (WADocumentStreamViewController *)initWithDate:(NSDate *)date;

@end
