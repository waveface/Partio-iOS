//
//  WAWebServiceSettingsViewController.h
//  wammer
//
//  Created by kchiu on 12/11/28.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAOAuthSwitch.h"

@interface WAWebServiceSettingsViewController : UITableViewController <WAOAuthSwitchDelegate>

@property (weak, nonatomic) IBOutlet UITableViewCell *facebookConnectCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *twitterConnectCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *foursquareConnectCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *flickrConnectCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *picasaConnectCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *googleConnectCell;

@end
