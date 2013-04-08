//
//  WAPartioWelcomeViewController.m
//  wammer
//
//  Created by Shen Steven on 4/6/13.
//  Copyright (c) 2013 Waveface. All rights reserved.
//

#import "WAPartioWelcomeViewController.h"
#import "WAPartioFirstUseViewController.h"
#import "WAOverlayBezel.h"
#import "WARemoteInterface.h"
#import <Accounts/Accounts.h>
#import <FacebookSDK/FacebookSDK.h>

@interface WAPartioWelcomeViewController ()

@end

@implementation WAPartioWelcomeViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  
  WAPartioFirstUseViewController *firstUse = (WAPartioFirstUseViewController*)self.navigationController;
  
  if (indexPath.row == 0) {
    if (firstUse.completionBlock)
      firstUse.completionBlock();
  } else if (indexPath.row == 1) {
    
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
}

@end
