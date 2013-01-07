//
//  WAStatusBar.h
//  wammer
//
//  Created by kchiu on 12/11/15.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^WAStatusBarDidDismiss)(void);

@interface WAStatusBar : UIWindow

@property (nonatomic, strong) UILabel *syncingLabel;

- (void)showPhotoImportingWithImportedFilesCount:(NSUInteger)importedFilesCount needingImportFilesCount:(NSUInteger)needingImportFilesCount;
- (void)showPhotoSyncingWithSyncedFilesCount:(NSUInteger)syncedFilesCount needingSyncFilesCount:(NSUInteger)needingSyncFilesCount;
- (void)startFetchingAnimation;
- (void)stopFetchingAnimation;
- (void)showSyncCompleteWithDissmissBlock:(WAStatusBarDidDismiss)dismissBlock;
- (void)showSyncFailWithDismissBlock:(WAStatusBarDidDismiss)dismissBlock;

@end
