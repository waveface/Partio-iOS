//
//  WAFacebookSignupViewController.m
//  wammer
//
//  Created by Shen Steven on 4/11/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAFacebookSignupViewController.h"
#import "WAOverlayBezel.h"
#import "WARemoteInterface.h"
#import "UIKit+IRAdditions.h"
#import "WAPartioFirstUseViewController.h"
#import <Accounts/Accounts.h>
#import <FacebookSDK/FacebookSDK.h>


@interface WAFacebookSignupViewController ()

@end

@implementation WAFacebookSignupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)facebookSignupButtonClicked:(id)sender {
  WAPartioFirstUseViewController *firstUse = (WAPartioFirstUseViewController*)self.navigationController;

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
        
        dispatch_async(dispatch_get_main_queue(), ^{
          if (firstUse.completionBlock)
            firstUse.completionBlock();
        });
        
        
      } onFailure:^(NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
          
          [busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
          
          if (firstUse.failureBlock)
            firstUse.failureBlock(error);
          
        });
        
      }];
     
   }];

}

@end
