//
//  WADocumentDownloadingView.h
//  wammer
//
//  Created by kchiu on 12/12/13.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WADocumentDownloadingView : UIView

@property (weak, nonatomic) IBOutlet UILabel *downloadTitle;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgress;

@end
