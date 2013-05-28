//
//  WAPartioWelcomeViewController.m
//  wammer
//
//  Created by Shen Steven on 4/6/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPartioWelcomeViewController.h"
#import "WAPartioFirstUseViewController.h"
#import "UIKit+IRAdditions.h"
#import "WAOverlayBezel.h"
#import "WARemoteInterface.h"
#import "WAPartioFirstUseViewController.h"
#import "WAAppDelegate_iOS.h"
#import "WADefines.h"
#import <Accounts/Accounts.h>
#import <FacebookSDK/FacebookSDK.h>

@interface WAPartioWelcomeViewController ()
@property (nonatomic, weak) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic, weak) IBOutlet UIButton *experienceButton;
@property (nonatomic, weak) IBOutlet UIButton *signupButton;
@property (nonatomic, strong) WAOverlayBezel *busyBezel;
@end



@implementation WAPartioWelcomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (void) viewDidLoad {
  
  [super viewDidLoad];
  
  [self.experienceButton setBackgroundColor:[UIColor colorWithWhite:255 alpha:0.4]];
  self.experienceButton.layer.cornerRadius = 22;
  
  if(IS_WIDESCREEN)
    self.backgroundImageView.image = [UIImage imageNamed:@"PartioLogin-568h"];
  else
    self.backgroundImageView.image = [UIImage imageNamed:@"PartioLogin"];
  
  UIImageView *fbIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"fbicon"]];
  fbIcon.frame = (CGRect){{20, 0}, {44, 44}};
  fbIcon.contentMode = UIViewContentModeScaleAspectFit;
  UILabel *signupLabel = [[UILabel alloc] init];
  signupLabel.text = NSLocalizedString(@"SIGNUP_BUTTON", @"");
  signupLabel.backgroundColor = [UIColor clearColor];
  signupLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:15.f];
  signupLabel.textColor = [UIColor whiteColor];
  [signupLabel sizeToFit];
  signupLabel.frame = (CGRect){{67, 0}, {signupLabel.frame.size.width, 44}};
  [self.signupButton addSubview:fbIcon];
  [self.signupButton addSubview:signupLabel];
  
}

- (void)firstArticleFetchedHandler:(NSNotification*)aNotification {
  __weak WAPartioWelcomeViewController *wSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
  
    if (wSelf.busyBezel) {
      [wSelf.busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
      wSelf.busyBezel = nil;
      [[NSNotificationCenter defaultCenter] removeObserver:wSelf name:kWARemoteInterfaceDidFetchArticleNotification object:nil];
    }
    
    WAPartioFirstUseViewController *firstUse = (WAPartioFirstUseViewController*)wSelf.navigationController;
    if (firstUse.completionBlock) {
      firstUse.completionBlock(YES);
      firstUse.completionBlock = nil;
    }
  });

}



- (IBAction) experienceButtonClicked:(id)sender {
  
  self.experienceButton.enabled = NO;
  self.signupButton.enabled = NO;
  __weak WAPartioWelcomeViewController *wSelf = self;
  WAPartioFirstUseViewController *firstUse = (WAPartioFirstUseViewController *)self.navigationController;
  if (firstUse.completionBlock) {
    firstUse.completionBlock(NO);
    
    wSelf.experienceButton.enabled = YES;
    wSelf.signupButton.enabled = YES;
    
  }
}

- (IBAction) signupButtonClicked:(id)sender {
  
  WAPartioFirstUseViewController *firstUse = (WAPartioFirstUseViewController*)self.navigationController;
  
  self.experienceButton.enabled = NO;
  self.signupButton.enabled = NO;
  self.busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
  [self.busyBezel showWithAnimation:WAOverlayBezelAnimationFade];
  self.busyBezel.caption = @"Signin...";
  
  // http://stackoverflow.com/questions/12601191/facebook-sdk-3-1-error-validating-access-token
  // This should and will be fixed from FB SDK
  
  ACAccountStore *accountStore;
  ACAccountType *accountTypeFB;
  if ((accountStore = [[ACAccountStore alloc] init]) &&
      (accountTypeFB = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook] ) ){
    
    NSArray *fbAccounts = [accountStore accountsWithAccountType:accountTypeFB];
    id account;
    if (fbAccounts && [fbAccounts count] > 0 &&
        (account = [fbAccounts objectAtIndex:0])){
      
      [accountStore renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
        //we don't actually need to inspect renewResult or error.
        if (error){
          
        }
      }];
    }
  }
  
  __weak WAPartioWelcomeViewController *wSelf = self;
  
  [FBSession
   openActiveSessionWithReadPermissions:@[@"email", @"user_photos", @"user_status", @"read_stream", @"friends_checkins", @"user_checkins"]
   allowLoginUI:YES
   completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
     
     if (error) {
       
       NSLog(@"Facebook auth error: %@", error);
       dispatch_async(dispatch_get_main_queue(), ^{
         
         [wSelf.busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
         wSelf.experienceButton.enabled = YES;
         wSelf.signupButton.enabled = YES;
         
         if (firstUse.failureBlock)
           firstUse.failureBlock(error);
         
       });
       
       
       return;
     }
     
     [[WARemoteInterface sharedInterface]
      signupUserWithFacebookToken:session.accessTokenData.accessToken
      withOptions:nil
      onSuccess:^(NSString *token, NSDictionary *userRep, NSArray *groupReps) {
        NSString *userID = [userRep valueForKeyPath:@"user_id"];
        
        NSString *primaryGroupID = [[[groupReps filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
          
          return [[evaluatedObject valueForKeyPath:@"creator_id"] isEqual:userID];
          
        }]] lastObject] valueForKeyPath:@"group_id"];
        
        WARemoteInterface *ri = [WARemoteInterface sharedInterface];
        ri.userIdentifier = userID;
        ri.userToken = token;
        ri.primaryGroupIdentifier = primaryGroupID;
        
        wSelf.busyBezel.caption = @"Loading...";
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(firstArticleFetchedHandler:) name:kWARemoteInterfaceDidFetchArticleNotification object:nil];
        [wSelf performSelector:@selector(firstArticleFetchedHandler:) withObject:nil afterDelay:10];

        WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
        [appDelegate bootstrapWhenUserLogin];

      } onFailure:^(NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
          
          [wSelf.busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
          wSelf.experienceButton.enabled = YES;
          wSelf.signupButton.enabled = YES;

          if (firstUse.failureBlock)
            firstUse.failureBlock(error);
          
        });
        
      }];
     
   }];
  

}

- (BOOL) shouldAutorotate {
  return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

@end
