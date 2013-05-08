//
//  WAFacebookLoginViewController.m
//  wammer
//
//  Created by Shen Steven on 4/11/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAFacebookLoginViewController.h"
#import "UIKit+IRAdditions.h"
#import "WAOverlayBezel.h"
#import "WARemoteInterface.h"
#import "WAAppDelegate_iOS.h"
#import <FacebookSDK/FacebookSDK.h>
#import <Accounts/Accounts.h>

@interface WAFacebookLoginViewController ()
@property (nonatomic, copy) void (^completionHandler)(NSError *error);
@end

@implementation WAFacebookLoginViewController

- (id) initWithCompletionHandler:(void(^)(NSError *error))completion {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.completionHandler = completion;
  }
  return self;
}

+ (void) backgroundLoginWithFacebookIDWithCompleteHandler:(void(^)(NSError *error))completionHandler {
  
  WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
  [busyBezel showWithAnimation:WAOverlayBezelAnimationFade];
  
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
  
  
  [FBSession
   openActiveSessionWithReadPermissions:@[@"email", @"user_photos", @"user_videos", @"user_notes", @"user_status", @"user_likes", @"read_stream", @"friends_photos", @"friends_videos", @"friends_status", @"friends_notes", @"friends_likes"]
   allowLoginUI:YES
   completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
     
     if (error) {
       
       NSLog(@"Facebook auth error: %@", error);
       dispatch_async(dispatch_get_main_queue(), ^{
         
         [busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
         if (completionHandler)
           completionHandler(error);
         
       });
       
       return;
     }
     
     [[WARemoteInterface sharedInterface]
      signupUserWithFacebookToken:session.accessTokenData.accessToken
      withOptions:nil
      onSuccess:^(NSString *token, NSDictionary *userRep, NSArray *groupReps) {
        
        WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
        
        NSString *userID = [userRep valueForKeyPath:@"user_id"];
        
        NSString *primaryGroupID = [[[groupReps filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
          
          return [[evaluatedObject valueForKeyPath:@"creator_id"] isEqual:userID];
          
        }]] lastObject] valueForKeyPath:@"group_id"];
        
        
        ri.userIdentifier = userID;
        ri.userToken = token;
        ri.primaryGroupIdentifier = primaryGroupID;

        WAAppDelegate_iOS *appDelegate = (WAAppDelegate_iOS*)AppDelegate();
        [appDelegate bootstrapWhenUserLogin];
        
        dispatch_async(dispatch_get_main_queue(), ^{

          [busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];

          if (completionHandler)
            completionHandler(nil);          
          
        });
        
        
      } onFailure:^(NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
                    
          [busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
          
          if (completionHandler)
            completionHandler(error);

        });
        
      }];
     
   }];
  
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  if(IS_WIDESCREEN)
    self.imageView.image = [UIImage imageNamed:@"Default-568h"];
  else
    self.imageView.image = [UIImage imageNamed:@"Default"];

}

- (void) viewDidAppear:(BOOL)animated {
  __weak WAFacebookLoginViewController *wSelf = self;
  [[self class] backgroundLoginWithFacebookIDWithCompleteHandler:^(NSError *error) {
    wSelf.completionHandler(error);
  }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) shouldAutorotate {
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}
@end
