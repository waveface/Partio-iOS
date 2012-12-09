//
//  WADocumentStreamViewCell.h
//  wammer
//
//  Created by kchiu on 12/12/5.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAFilePageElement.h"

extern NSString * const kWADocumentStreamViewCellID;
extern NSString * kWADocumentStreamViewCellKVOContext;

@interface WADocumentStreamViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) WAFilePageElement *pageElement;

@end
