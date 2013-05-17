//
//  WAPartioSettingsViewController.m
//  wammer
//
//  Created by Shen Steven on 5/15/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPartioSettingsViewController.h"
#import "WADefines.h"
#import <QuartzCore/QuartzCore.h>
#import <BlocksKit/BlocksKit.h>

@interface WAPartioSettingsViewController () <MFMailComposeViewControllerDelegate>
@property (nonatomic, weak) IBOutlet UILabel *aboutTitle;
@property (nonatomic, weak) IBOutlet UILabel *description;
@property (nonatomic, weak) IBOutlet UILabel *subdescription;
@property (nonatomic, weak) IBOutlet UIButton *closedButton;
@property (nonatomic, weak) IBOutlet UIButton *supportButton;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@end

@implementation WAPartioSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.aboutTitle.font = [UIFont fontWithName:@"OpenSans-Semibold" size:20.f];
  self.aboutTitle.text = NSLocalizedString(@"GRUPIN_ABOUT_TEXT", @"");
  self.description.font = [UIFont fontWithName:@"OpenSans-Regular" size:14.f];
  self.description.text = NSLocalizedString(@"GRUPIN_ABOUT_DESC", @"");
  self.subdescription.font = [UIFont fontWithName:@"OpenSans-Semibold" size:16.f];
  self.subdescription.text = NSLocalizedString(@"GRUPIN_ABOUT_SUBDESC", @"");
   
  self.supportButton.layer.cornerRadius = 15;
  
}

- (IBAction)closedButtonTapped:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)supportButtonTapped:(id)sender {
 
  if (![MFMailComposeViewController canSendMail])
    return;
  
  MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
  mailer.mailComposeDelegate = self;
  NSString *subject = NSLocalizedString(@"SUBJECT_MAIL_LINK", @"The email subject to send waveface support");
  [mailer setSubject:subject];
  NSString *body = NSLocalizedString(@"BODY_MAIL_LINK", @"The content of email body to send waveface support");
  [mailer setMessageBody:body isHTML:NO];
  
  NSString *supportEmail = [[NSUserDefaults standardUserDefaults] stringForKey:WAFeedbackRecipient];
  if (supportEmail)
    [mailer setToRecipients:@[supportEmail]];
  [self presentViewController:mailer animated:YES completion:nil];

}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
  
  [controller dismissViewControllerAnimated:YES completion:nil];
  
}

- (BOOL)shouldAutorotate {
  return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
