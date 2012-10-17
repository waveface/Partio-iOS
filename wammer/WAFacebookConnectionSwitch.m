//
//  WAFacebookConnectionSwitch.m
//  wammer
//
//  Created by Evadne Wu on 7/18/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFacebookConnectionSwitch.h"
#import <FacebookSDK/FacebookSDK.h>
#import "WARemoteInterface.h"
#import "UIKit+IRAdditions.h"
#import "WAOverlayBezel.h"

NSString * const kWAFacebookUserDataImport = @"WAFacebookImportTimeLine";

@interface WAFacebookConnectionSwitch ()

- (void) commonInit;
- (void) reloadStatus;

@end


@implementation WAFacebookConnectionSwitch

- (id) initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];
	if (!self)
		return nil;
	
	[self commonInit];
	
	return self;

}

- (void) awakeFromNib {

	[super awakeFromNib];
	
	[self commonInit];

}

- (void)setOn:(BOOL)on animated:(BOOL)animated{
	[[NSUserDefaults standardUserDefaults] setBool:on forKey:kWAFacebookUserDataImport];
	[super setOn:on animated:animated];
}

- (void) commonInit {

	[self addTarget:self action:@selector(handleValueChanged:) forControlEvents:UIControlEventValueChanged];
	
	self.enabled = NO;
	
	[self reloadStatus];
	
}

- (void) reloadStatus {

	self.enabled = NO;
	self.on = [[NSUserDefaults standardUserDefaults] boolForKey:kWAFacebookUserDataImport];

	__weak WAFacebookConnectionSwitch *wSelf = self;
	
	WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	[ri retrieveConnectedSocialNetworksOnSuccess:^(NSArray *snsReps) {
	
		if (!wSelf)
			return;
	
		NSArray *facebookReps = [snsReps filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^ (id evaluatedObject, NSDictionary *bindings) {
			
			return [[evaluatedObject valueForKeyPath:@"type"] isEqual:@"facebook"];
			
		}]];
		
		NSCParameterAssert([facebookReps count] <= 1);
		NSDictionary *fbRep = [facebookReps lastObject];
		//	NSString *fbStatus = [fbRep valueForKeyPath:@"status"];
		NSNumber *fbImportingEnabled = [fbRep valueForKeyPath:@"enabled"];
		
		BOOL importing = [fbImportingEnabled isEqual:(id)kCFBooleanTrue];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			if (wSelf) {
				
				wSelf.enabled = YES;
				wSelf.on = importing;
				[wSelf setOn:importing animated:NO];

			}
			
		});
		
	} onFailure:^(NSError *error) {
	
		NSLog(@"error %@", error);
		
	}];
}

- (void) handleValueChanged:(id)sender {

	NSCParameterAssert(sender == self);
	
	if (self.on) {
		
		[[self newFacebookConnectAlertView] show];
	
	} else {
	
		[[self newFacebookDisconnectAlertView] show];
			
	}
	
}

- (NSString *) errorString:(NSUInteger) code
{
	if (code == 0x1002) {
		return NSLocalizedString(@"FACEBOOK_CONNECT_ACCOUNT_OCCUPIED_MESSAGE", @"Message for an alert view to show user his FB account has been connected to another Stream user");
	} else if (code == 0x2004) {
		return NSLocalizedString(@"FACEBOOK_CONNECT_FAIL_MESSAGE", @"Message for an alert view to show user he already connects to another FB account.");
	}
	return nil;
}

- (IRAlertView *) newFacebookConnectAlertView {

	__weak WAFacebookConnectionSwitch * const wSelf = self;
	
	NSString *cancelTitle = NSLocalizedString(@"ACTION_CANCEL", nil);
	IRAction *cancelAction = [IRAction actionWithTitle:cancelTitle block:^{
		
		[wSelf setOn:NO animated:YES];
		
	}];
	
	NSString *connectTitle = NSLocalizedString(@"ACTION_CONNECT_FACEBOOK_SHORT", @"Short action title for connecting Facebook creds");
	IRAction *connectAction = [IRAction actionWithTitle:connectTitle block:^{
	
		[wSelf handleFacebookConnect:nil];
				
	}];
	
	NSString *alertTitle = NSLocalizedString(@"FACEBOOK_CONNECT_REQUEST_TITLE", @"Title for alert view asking if user wants to connect her Facebook account");
	NSString *alertMessage = NSLocalizedString(@"FACEBOOK_CONNECT_REQUEST_MESSAGE", @"Message for alert view asking if user wants to connect her Facebook account");

	IRAlertView *alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertMessage cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:connectAction, nil]];
		
	return alertView;

}

- (void) handleFacebookConnect:(id)sender {

	__weak WAFacebookConnectionSwitch * const wSelf = self;
	
	if (FBSession.activeSession.isOpen) {
	
//		WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
//		[busyBezel showWithAnimation:WAOverlayBezelAnimationFade];
		
		[wSelf connectFacebookWithToken:FBSession.activeSession.accessToken onSuccess:^{
			
//			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
			
//			WAOverlayBezel *doneBezel = [WAOverlayBezel bezelWithStyle:WACheckmarkBezelStyle];
//			[doneBezel showWithAnimation:WAOverlayBezelAnimationNone];
//			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//				[doneBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
//			});
			
			[wSelf setOn:YES animated:YES];
			[wSelf setEnabled:YES];

		} onFailure:^(NSError *error) {
		
//			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
			
			[wSelf requestFacebookTokenWithCompletion:^(NSString *token, NSError *error) {
			
				if (token) {
				
					[wSelf setEnabled:NO];
					[wSelf setOn:YES animated:YES];
					
//					WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
//					[busyBezel showWithAnimation:WAOverlayBezelAnimationFade];
					
					[wSelf connectFacebookWithToken:token onSuccess:^{
						
//						[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];

						[wSelf setEnabled:YES];
						[wSelf setOn:YES animated:YES];

					} onFailure:^(NSError *error) {
						
//						[busyBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
//						
//						[[[IRAlertView alloc] initWithTitle:NSLocalizedString(@"FACEBOOK_CONNECT_FAIL_TITLE", @"Title for an alert view to show facebook connection failure") message:[wSelf errorString:[error code]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
						
						[wSelf setEnabled:YES];
						[wSelf setOn:NO animated:YES];

					}];

				} else {
				
//					[[[IRAlertView alloc] initWithTitle:NSLocalizedString(@"FACEBOOK_CONNECT_FAIL_TITLE", @"Title for an alert view to show facebook connection failure") message:[wSelf errorString:[error code]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
					[wSelf setEnabled:YES];
					[wSelf setOn:NO animated:YES];
					
					return;
				
				}
				
			}];
			
		}];
		
	} else {

		[wSelf requestFacebookTokenWithCompletion:^(NSString *token, NSError *error) {
		
			if (token) {
			
				[wSelf setEnabled:NO];
				[wSelf setOn:YES animated:YES];
				
//				WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
//				[busyBezel showWithAnimation:WAOverlayBezelAnimationFade];
				
				[wSelf connectFacebookWithToken:token onSuccess:^{
					
//					[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];

					[wSelf setEnabled:YES];
					[wSelf setOn:YES animated:YES];

				} onFailure:^(NSError *error) {
					
//					[busyBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
//					[[[IRAlertView alloc] initWithTitle:NSLocalizedString(@"FACEBOOK_CONNECT_FAIL_TITLE", @"Title for an alert view to show facebook connection failure") message:[wSelf errorString:[error code]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
					
					[wSelf setEnabled:YES];
					[wSelf setOn:NO animated:YES];

				}];

			} else {
			
//				[[[IRAlertView alloc] initWithTitle:NSLocalizedString(@"FACEBOOK_CONNECT_FAIL_TITLE", @"Title for an alert view to show facebook connection failure") message:[wSelf errorString:[error code]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
				
				[wSelf setEnabled:YES];
				[wSelf setOn:NO animated:YES];
				
				return;
			
			}
			
		}];
		
		[wSelf setOn:NO animated:NO];
	
	}

}

- (IRAlertView *) newFacebookDisconnectAlertView {

	__weak WAFacebookConnectionSwitch * const wSelf = self;
	
	NSString *cancelTitle = NSLocalizedString(@"ACTION_CANCEL", nil);
	IRAction *cancelAction = [IRAction actionWithTitle:cancelTitle block:^{
		
		[wSelf setOn:YES animated:YES];
		
	}];
	
	NSString *disconnectTitle = NSLocalizedString(@"ACTION_DISCONNECT_FACEBOOK", @"Short action title for disconnecting Facebook creds");
	IRAction *disconnectAction = [IRAction actionWithTitle:disconnectTitle block:^{
	
		[wSelf handleFacebookDisconnect:nil];
	
	}];
	
	NSString *alertTitle = NSLocalizedString(@"FACEBOOK_DISCONNECT_REQUEST_TITLE", @"Title for alert view asking if user wants to disconnect her Facebook account");
	NSString *alertMessage = NSLocalizedString(@"FACEBOOK_DISCONNECT_REQUEST_MESSAGE", @"Message for alert view asking if user wants to disconnect her Facebook account");

	IRAlertView *alertView = [IRAlertView alertViewWithTitle:alertTitle message:alertMessage cancelAction:cancelAction otherActions:[NSArray arrayWithObjects:disconnectAction, nil]];
	
	return alertView;

}

- (void) handleFacebookDisconnect:(id)sender {

	__weak WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	__weak WAFacebookConnectionSwitch * const wSelf = self;
	
	wSelf.enabled = NO;

	WAOverlayBezel *busyBezel = [WAOverlayBezel bezelWithStyle:WAActivityIndicatorBezelStyle];
	[busyBezel showWithAnimation:WAOverlayBezelAnimationFade];

	[ri disconnectSocialNetwork:@"facebook" purgeData:NO onSuccess:^{

		dispatch_async(dispatch_get_main_queue(), ^{
			
			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
	
			if (!wSelf)
				return;

			wSelf.enabled = YES;
			[wSelf setOn:NO animated:NO];
			
		});
		
	} onFailure:^(NSError *error) {
	
		dispatch_async(dispatch_get_main_queue(), ^{
		
			[busyBezel dismissWithAnimation:WAOverlayBezelAnimationNone];
			
			WAOverlayBezel *errorBezel = [WAOverlayBezel bezelWithStyle:WAErrorBezelStyle];
			[errorBezel showWithAnimation:WAOverlayBezelAnimationNone];

			if (!wSelf)
				return;
			
			wSelf.enabled = YES;
			[wSelf setOn:YES animated:YES];
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			
				[errorBezel dismissWithAnimation:WAOverlayBezelAnimationFade];
				
			});

		});
		
	}];

}

- (void) connectFacebookWithToken:(NSString *)token onSuccess:(void(^)(void))successBlock onFailure:(void(^)(NSError *error))failureBlock {

	__weak WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	
	[ri connectSocialNetwork:@"facebook" withToken:token onSuccess:^{
	
		if (successBlock) {
		
			dispatch_async(dispatch_get_main_queue(), ^{
			
				successBlock();
				
			});
		
		}
		
	} onFailure:^(NSError *error) {
	
		if (failureBlock) {
			
			dispatch_async(dispatch_get_main_queue(), ^{
			
				failureBlock(error);
				
			});
			
		}
		
	}];

}

- (void) requestFacebookTokenWithCompletion:(void(^)(NSString *token, NSError *error))block {
	[FBSession
	 openActiveSessionWithReadPermissions:nil
	 allowLoginUI:NO
	 completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
		 
		 NSString *token = error ? nil : session.accessToken;
		 dispatch_async(dispatch_get_main_queue(), ^{
			 if (block) {
				 block(token, error);
			 }
		 });
		 
	 }];
}

@end
