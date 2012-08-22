//
//  WATutorialViewController.h
//  wammer
//
//  Created by Evadne Wu on 7/13/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIKit+IRAdditions.h"


enum WATutorialInstantiationOption {
	WATutorialInstantiationOptionDefault,
  WATutorialInstantiationOptionShowFacebookIntegrationToggle
};

typedef NSUInteger WATutorialInstantiationOption;

typedef void (^WATutorialViewControllerCallback)(BOOL didFinish, NSError *error);


@interface WATutorialViewController : UIViewController

+ (WATutorialViewController *) controllerWithOption:(WATutorialInstantiationOption)option completion:(WATutorialViewControllerCallback)block;

@property (weak, nonatomic) IBOutlet IRPaginatedView *paginatedView;
@property (weak, nonatomic) IBOutlet UIView *pageWelcomeToStream;
@property (weak, nonatomic) IBOutlet UIView *pageReliveYourMoments;
@property (weak, nonatomic) IBOutlet UIView *pageInstallStation;
@property (weak, nonatomic) IBOutlet UIView *pageToggleFacebook;
@property (weak, nonatomic) IBOutlet UIView *pageStartStream;
@property (weak, nonatomic) IBOutlet UIButton *goButton;

- (IBAction) handleGo:(id)sender;

@end
